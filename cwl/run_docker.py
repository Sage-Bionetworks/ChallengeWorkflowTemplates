"""Run participant Docker model and store logs."""

from __future__ import print_function

import argparse
import glob
import json
import os
import tempfile

import docker
import requests
import synapseclient


def get_docker_client_and_login(
    synapse_config_path: str,
) -> docker.DockerClient:
    """
    Initializes the Docker client and log into the Synapse Docker Registry.
    """
    try:
        client = docker.DockerClient(base_url="unix://var/run/docker.sock")
        config = synapseclient.Synapse().getConfigFile(configPath=synapse_config_path)
        authen = dict(config.items("authentication"))
        client.login(
            username=authen["username"],
            password=authen["authtoken"],
            registry="https://docker.synapse.org",
        )
    except docker.errors.APIError:
        client = docker.from_env()
    return client


def create_log_file(log_filename: str, log_text: str | bytes | None = None):
    """Create log file"""
    with open(log_filename, "w") as log_file:
        if isinstance(log_text, bytes):
            log_text = log_text.decode("utf-8")
        log_file.write(log_text.encode("ascii", "ignore").decode("ascii"))


def get_log_tail(log_filename: str, n: int = 5) -> str:
    """Reads the last N lines of a log file."""
    with open(log_filename, "rb") as f:
        try:
            f.seek(-2, os.SEEK_END)

            # Keep reading, starting at the end, until n lines is read.
            lines_read = 0
            while lines_read < n:
                f.seek(-2, os.SEEK_CUR)
                if f.read(1) == b"\n":
                    lines_read += 1
        except OSError:
            # If file only contains one line, only read that one line.
            f.seek(0)
        return f.read().decode()


def store_log_file(syn, log_filename, parentid, store=True):
    """Store log file"""
    statinfo = os.stat(log_filename)
    if statinfo.st_size > 0:
        # If log file is larger than 50Kb, only save last few lines.
        if statinfo.st_size / 1000.0 > 50:
            log_tail = get_log_tail(log_filename)
            create_log_file(log_filename, log_tail)
        ent = synapseclient.File(log_filename, parent=parentid)
        if store:
            try:
                syn.store(ent)
            except synapseclient.exceptions.SynapseHTTPError as err:
                print(err)


def remove_docker_container(client, container_name):
    """Remove docker container"""
    try:
        cont = client.containers.get(container_name)
        cont.stop()
        cont.remove()
    except Exception:
        print(f"Unable to remove container: {container_name}")


def pull_docker_image(client, image_name):
    """Pull docker image"""
    try:
        client.images.pull(image_name)
    except docker.errors.ImageNotFound:
        print(f"Image incompatible with the `linux/amd64 architecture; pl")
    except Exception:
        print(f"Unable to pull image: {image_name}")


def remove_docker_image(client, image_name):
    """Remove docker image"""
    try:
        client.images.remove(image_name, force=True)
    except Exception:
        print(f"Unable to remove image: {image_name}")


def run_docker(syn, args, docker_client, output_dir_to_mount):
    """Run the participant's Docker model.

    The container execution is subject to a time limit. This timeout ensures
    the system prevents resource exhaustion and keeps the evaluation queue moving.
    """
    docker_image = f"{args.docker_repository}@{args.docker_digest}"
    container_name = f"{args.submissionid}-docker_run"
    log_filename = f"{args.submissionid}-docker_logs.txt"
    input_dir = args.input_dir
    timeout = args.container_time_limit

    print("Mounting volumes...")
    volumes = {
        input_dir: {
            "bind": "/input",
            "mode": "ro",
        },
        output_dir_to_mount: {
            "bind": "/output",
            "mode": "rw",
        },
    }

    # Remove any pre-existing container with the same name
    remove_docker_container(docker_client, container_name)

    print("Pulling submitted Docker image...")
    try:
        docker_client.images.pull(docker_image)
    except docker.errors.APIError as err:
        errors = f"Unable to pull image: {err}"
        return False, errors

    print(f"Running container '{container_name}'...")
    try:
        container = docker_client.containers.run(
            docker_image,
            detach=True,
            volumes=volumes,
            name=container_name,
            network_disabled=True,
            mem_limit=args.container_memory_limit,
            shm_size="1g",
            stderr=True,
        )

        # Wait for the container to finish
        container.wait(timeout=timeout)
        log_text = container.logs() or "Container did not produce any STDOUT or logs."
        create_log_file(log_filename, log_text=log_text)
        store_log_file(syn, log_filename, args.parentid, store=args.store)
        container.remove()
        return True, ""
    except requests.exceptions.ConnectionError:
        log_text = (
            f"Container exceeded execution time limit of {timeout / 60} "
            "minutes; stopping container."
        )
        remove_docker_container(docker_client, container_name)
        create_log_file(log_filename, log_text=log_text)
        store_log_file(syn, log_filename, args.parentid, store=args.store)
        container.remove()
        return False, log_text
    except Exception as err:
        log_text = f"Error running container: {err}"
        create_log_file(log_filename, log_text=log_text)
        store_log_file(syn, log_filename, args.parentid, store=args.store)
        container.remove()
        return False, log_text


def main(args):
    """Main function."""

    status = "VALIDATED_DOCKER"
    invalid_reasons = ""
    expected_output = "predictions.csv"

    # Initial check for valid Docker image submission; skip to end if invalid.
    if not args.docker_repository and not args.docker_digest:
        status = "INVALID"
        invalid_reasons = "Submission is not a Docker image, please try again."
    else:
        # Login to Synapse.
        syn = synapseclient.Synapse(configPath=args.synapse_config)
        syn.login(silent=True)

        # Login to the Synapse docker registry.
        client = get_docker_client_and_login(args.synapse_config)

        # Create temporary output directory to mount to container
        current_working_dir = os.getcwd()
        with tempfile.TemporaryDirectory(dir=current_working_dir) as output_dir:

            # Update permissions so that non-root container can write to it
            os.chmod(output_dir, 0o777)

            success, run_error = run_docker(syn, args, client, output_dir)
            if not success:
                status = "INVALID"
                invalid_reasons = run_error
            else:
                output_file = glob.glob(os.path.join(output_dir, expected_output))
                if output_file:
                    os.rename(
                        output_file[0],
                        os.path.join(current_working_dir, expected_output),
                    )
                else:
                    status = "INVALID"
                    invalid_reasons = (
                        f"Container did not generate a file called {expected_output}"
                    )
        remove_docker_image(client, f"{args.docker_repository}@{args.docker_digest}")

    with open("results.json", "w") as out:
        out.write(
            json.dumps(
                {
                    "submission_status": status,
                    "submission_errors": invalid_reasons,
                    "admin_folder": args.parentid,
                }
            )
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c",
        "--synapse_config",
        required=True,
        help="Filepath to Synapse credentials file",
    )
    parser.add_argument(
        "-s",
        "--submissionid",
        required=True,
        help="Submission ID",
    )
    parser.add_argument(
        "--parentid",
        required=True,
        help="Parent Synapse ID (Folder) for storing logs",
    )
    parser.add_argument(
        "--docker_repository",
        required=True,
        help="Docker image name",
    )
    parser.add_argument(
        "--docker_digest",
        required=True,
        help="Docker digest",
    )
    parser.add_argument(
        "-i",
        "--input_dir",
        required=True,
        help="Absolute path to the input data directory",
    )
    parser.add_argument(
        "--container_time_limit",
        type=int,
        default=7200,
        help="Container execution timeout in seconds (default: 7200s / 2h)",
    )
    parser.add_argument(
        "--container_memory_limit",
        default="2g",
        help="Container memory limit (default: 2g). Must be at least 6m (6 megabytes)",
    )
    parser.add_argument(
        "--container_memory_swap_limit",
        default="2g",
        help=(
            "Amount of memory container is allowed to swap to disk (default: 2g). "
            "If this value is less than or equal to 'container_memory_limit', "
            "container will not have access to swap."
        ),
    )
    parser.add_argument(
        "--store",
        action="store_true",
        help="Store container logs in Synapse",
    )
    args = parser.parse_args()
    main(args)
