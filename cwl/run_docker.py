"""Minimal script to run a participant's Docker container."""

import argparse
import os
import tempfile

import docker
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


def main(args):
    docker_image = f"{args.docker_repository}@{args.docker_digest}"
    container_name = f"{args.submissionid}-run"
    expected_output = "predictions.csv"

    # 1. Initialize Docker client and login
    client = get_docker_client_and_login(args.synapse_config)

    # 2. Pull image
    print(f"Pulling image {docker_image}...")
    client.images.pull(docker_image)

    # 3. Create temp directory and run container
    with tempfile.TemporaryDirectory(dir=os.getcwd()) as output_dir:
        # 0o1777 grants write access to non-root container users
        os.chmod(output_dir, 0o1777)

        volumes = {
            args.input_dir: {"bind": "/input", "mode": "ro"},
            output_dir: {"bind": "/output", "mode": "rw"},
        }

        print(f"Running container '{container_name}'...")
        try:
            container = client.containers.run(
                docker_image,
                detach=True,
                name=container_name,
                volumes=volumes,
                network_disabled=True,
                mem_limit=args.container_memory_limit,
            )

            # Wait for execution to complete (with timeout)
            container.wait(timeout=args.container_time_limit)

            # Move output file if generated
            target_path = os.path.join(output_dir, expected_output)
            if os.path.exists(target_path):
                os.rename(target_path, os.path.join(os.getcwd(), expected_output))
                print(f"Successfully generated {expected_output}")
            else:
                print(f"Error: Container finished but did not produce {expected_output}")

        finally:
            # Clean up container and image
            try:
                client.containers.get(container_name).remove(force=True)
            except Exception:
                pass
            try:
                client.images.remove(docker_image, force=True)
            except Exception:
                pass


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
