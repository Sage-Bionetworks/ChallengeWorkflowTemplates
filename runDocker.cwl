#!/usr/bin/env cwl-runner
#
# Run Docker Submission
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python
arguments: 
  - valueFrom: runDocker.py
  - valueFrom: $(inputs.submissionId)
    prefix: -s
  - valueFrom: $(inputs.dockerRepository)
    prefix: -p
  - valueFrom: $(inputs.dockerDigest)
    prefix: -d
#  - valueFrom: $(inputs.inputDir)
#    prefix: -i
  #Docker run has access to the local file system, so this path is the input directory locally
  - valueFrom: /Users/ThomasY/Documents/
    prefix: -i
  - valueFrom: $(runtime.tmpdir)/$((runtime.outdir).split('/').slice(2).join("/"))
    prefix: -o
#  - valueFrom: $(runtime.tmpdir)/$((runtime.outdir).split('/').slice(-1)[0])
#    prefix: -o


#/Users/ThomasY/sandbox/temp/297f782e-5087-4f33-937f-a8cc20a39d57/tmp/tmpPKPyAL/5/3/out_tmpdirqAe90Q/listOfFiles.csv

requirements:
  - class: InitialWorkDirRequirement
    listing:
     # - entryname: listOfFiles.csv
     #   entry: |
     #     "foo"
      - entryname: .docker/config.json
        entry: |
          {"auths": {"$(inputs.dockerRegistry)": {"auth": "$(inputs.dockerAuth)"}}}
      - entryname: runDocker.py
        entry: |
          import docker
          import argparse
          import os
          #import shutil
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

          #OUTPUT_DIR = os.path.join(args.outputDir,args.submissionId)
          #os.mkdir(OUTPUT_DIR)
          OUTPUT_DIR = args.outputDir
          INPUT_DIR = args.inputDir
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

          #TODO: Look for if the container exists already, if so, reconnect 

          container=None
          for cont in client.containers.list(all=True):
            if args.submissionId in cont.name:
              #Must remove container if the container wasn't killed properly
              if cont.status == "exited":
                cont.remove()
              else:
                container = cont
          # If the container doesn't exist, make sure to run the docker image
          if container is None:
            #Run as detached, logs will stream below
            container = client.containers.run(dockerImage,detach=True, volumes = volumes, name=args.submissionId, network_disabled=True)

          # If the container doesn't exist, there are no logs to write out and no container to remove
          if container is not None:
            #These lines below will run as long as the container is running
            for line in container.logs(stream=True):
              print(line.strip())
            print("finished")
            #Remove container and image after being done
            #container.remove()
            #try:
            #    client.images.remove(dockerImage)
            #except:
            #    print("Unable to remove image")
          #Temporary hack to rename file
            print(OUTPUT_DIR)
            print(os.listdir(OUTPUT_DIR))
            curDir = os.getcwd()
            print(os.listdir(curDir))
            print(os.path.abspath("listOfFiles.csv"))
            #temp = os.path.abspath("listOfFiles.csv")

            #os.system("echo %s > listOfFiles.csv" % temp)
            #shutil.copy
            #os.system(os.path.join(OUTPUT_DIR,"listOfFiles.csv"), "listOfFiles.csv")
  - class: InlineJavascriptRequirement

inputs:
  - id: submissionId
    type: int
  - id: dockerRepository
    type: string
  - id: dockerDigest
    type: string
  - id: dockerRegistry
    type: string
  - id: dockerAuth
    type: string

outputs:
  predictions:
    type: File
    outputBinding:
      glob: listOfFiles.csv