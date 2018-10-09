import docker
import argparse
import os
parser = argparse.ArgumentParser()
parser.add_argument("-s", "--submissionId", required=True, help="Submission Id")
parser.add_argument("-p", "--dockerRepository", required=True, help="Docker Repository")
parser.add_argument("-d", "--dockerDigest", required=True, help="Docker Digest")
parser.add_argument("-i", "--inputDir", required=True, help="Input Directory")
parser.add_argument("-o", "--outputDir", required=True, help="Output Directory")
args = parser.parse_args()

client = docker.from_env()
#Add docker.config file
dockerImage = args.dockerRepository + "@" + args.dockerDigest

#These are the volumes that you want to mount onto your docker container
OUTPUT_DIR = os.path.abspath(args.outputDir)
INPUT_DIR = os.path.abspath(args.inputDir)

#These are the locations on the docker that you want your mounted volumes to be + permissions in docker (ro, rw)
#It has to be in this format '/output:rw'
MOUNTED_VOLUMES = {OUTPUT_DIR:'/output:rw',
                   INPUT_DIR:'/input:ro'}
#All mounted volumes here in a list
ALL_VOLUMES = [OUTPUT_DIR,INPUT_DIR]
#Mount volumes
volumes = {}
for vol in ALL_VOLUMES:
    volumes[vol] = {'bind': MOUNTED_VOLUMES[vol].split(":")[0], 'mode': MOUNTED_VOLUMES[vol].split(":")[1]}

#Look for if the container exists already, if so, reconnect 
container=None
for cont in client.containers.list():
	if args.submissionId in cont.name:
		container = cont

# If the container doesn't exist, make sure to run the docker image
if container is None:
	errors = None
	try:
		#Run as detached, logs will stream below
	    container = client.containers.run(dockerImage,detach=True, volumes = volumes, name=args.submissionId, network_disabled=True)
	except docker.errors.APIError as e:
	    container = None
	    errors = str(e) + "\n"

# If the container doesn't exist, there are no logs to write out and no container to remove
if container is not None:
	#These lines below will run as long as the container is running
	for line in container.logs(stream=True):
		print(line.strip())

	#Remove container and image after being done
	container.remove()
	try:
	    client.images.remove(dockerImage)
	except:
	    print("Unable to remove image")


