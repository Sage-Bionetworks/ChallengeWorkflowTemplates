#!/usr/bin/env cwl-runner
#
# Extracts the Synapse credentials and format into Docker config
# Since the Synapse Docker registry has the same password as Synapse
#

$namespaces:
  s: https://schema.org/

s:author:
  - class: s:Person
    s:identifier: https://orcid.org/0000-0002-5841-0198
    s:email: thomas.yu@sagebionetworks.org
    s:name: Thomas Yu

cwlVersion: v1.0
class: CommandLineTool
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.2.2

inputs:
  - id: synapse_config
    type: File

arguments:
  - valueFrom: get_docker_config.py
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: results.json
    prefix: -r

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: get_docker_config.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          import base64
          parser = argparse.ArgumentParser()
          parser.add_argument("-r", "--results", required=True, help="validation results")
          parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
          args = parser.parse_args()

          #Must read in credentials (username and password)
          config = synapseclient.Synapse().getConfigFile(configPath=args.synapse_config)
          authen = dict(config.items("authentication"))
          if authen.get("username") is None and authen.get("password") is None:
            raise Exception('Config file must have username and password')
          authen_string = "{}:{}".format(authen['username'], authen['password'])
          docker_auth = base64.encodestring(authen_string.encode('utf-8'))

          result = {'docker_auth':docker_auth.decode('utf-8'),'docker_registry':'https://docker.synapse.org'}
          with open(args.results, 'w') as o:
            o.write(json.dumps(result))

outputs:

  - id: results
    type: File
    outputBinding:
      glob: results.json   

  - id: docker_registry
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['docker_registry'])

  - id: docker_authentication
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['docker_auth'])
