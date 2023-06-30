#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Create a Docker config
doc: >
  Extract the Synapse credentials and formats it into a Docker config, in
  order to enable pulling from the Synapse Docker registry.

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

inputs:
- id: synapse_config
  type: File

outputs:
- id: results
  type: File
  outputBinding:
    glob: results.json
- id: docker_registry
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['docker_registry'])
    loadContents: true
- id: docker_authentication
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['docker_auth'])
    loadContents: true

baseCommand: python3
arguments:
- valueFrom: get_docker_config.py
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- prefix: -r
  valueFrom: results.json

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/synapseclient.txt

s:author:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5841-0198
  s:email: thomas.yu@sagebionetworks.org
  s:name: Thomas Yu

- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5622-7998
  s:email: verena.chung@sagebase.org
  s:name: Verena Chung

s:codeRepository: https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates
s:license: https://spdx.org/licenses/Apache-2.0

$namespaces:
  s: https://schema.org/
