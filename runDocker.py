import docker
import synapseclient
import json
import argparse


# inputs:
#   - id: submissionId
#     type: int
#   - id: dockerRepository
#     type: string
#   - id: dockerDigest
#     type: string
#   - id: dockerRegistry
#     type: string
#   - id: dockerAuth
#     type: string
client = docker.from_env()
#Add docker.config file
dockerImage = dockerRepository + "@" + dockerDigest

#These are the volumes that you want to mount onto your docker container
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),submission.id)
TESTDATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),'test-data')
CACHE = "/.synapseCache"
#These are the locations on the docker that you want your mounted volumes to be + permissions in docker (ro, rw)
#It has to be in this format '/output:rw'
MOUNTED_VOLUMES = {OUTPUT_DIR:'/output:rw',
                   TESTDATA_DIR:'/test-data:ro',
                   CACHE:'/.synapseCache:ro'}
#All mounted volumes here in a list
ALL_VOLUMES = [OUTPUT_DIR,TESTDATA_DIR,CACHE]
#Mount volumes
volumes = {}
for vol in ALL_VOLUMES:
    volumes[vol] = {'bind': MOUNTED_VOLUMES[vol].split(":")[0], 'mode': MOUNTED_VOLUMES[vol].split(":")[1]}

#TODO: Look for if the container exists already, if so, reconnect 
errors = None
try:
    container = client.containers.run(dockerImage, detach=True,volumes = volumes, name=submissionId, network_disabled=True)
except docker.errors.APIError as e:
    container = None
    errors = str(e) + "\n"

#Remove container and image after being done
container.remove()
try:
    client.images.remove(dockerImage)
except:
    print("Unable to remove image")






