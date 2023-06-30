#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Upload to Synapse
doc: >
  Upload a file to the given parent id on Synapse.

requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entryname: upload_file.py
    entry: |
      #!/usr/bin/env python
      import synapseclient
      import argparse
      import json
      if __name__ == '__main__':
        parser = argparse.ArgumentParser()
        parser.add_argument("-f", "--infile", required=True, help="file to upload")
        parser.add_argument("-p", "--parentid", required=True, help="Synapse parent for file")
        parser.add_argument("-ui", "--used_entityid", required=False, help="id of entity 'used' as input")
        parser.add_argument("-uv", "--used_entity_version", required=False, help="version of entity 'used' as input")
        parser.add_argument("-e", "--executed_entity", required=False, help="Syn ID of workflow which was executed")
        parser.add_argument("-r", "--results", required=True, help="Results of file upload")
        parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
        args = parser.parse_args()
        syn = synapseclient.Synapse(configPath=args.synapse_config)
        syn.login()
        file = synapseclient.File(path=args.infile, parent=args.parentid)
        try:
          file = syn.store(file,
                           used={'reference': {'targetId': args.used_entityid,
                                               'targetVersionNumber':args.used_entity_version}},
                           executed=args.executed_entity)
          fileid = file.id
          fileversion = file.versionNumber
        except Exception:
          fileid = ''
          fileversion = 0
        results = {'prediction_fileid': fileid,
                   'prediction_file_version': fileversion}
        with open(args.results, 'w') as o:
          o.write(json.dumps(results))

inputs:
- id: infile
  type: File
- id: parentid
  type: string
- id: used_entity
  type: string
- id: executed_entity
  type: string
- id: synapse_config
  type: File

outputs:
- id: uploaded_fileid
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['prediction_fileid'])
    loadContents: true
- id: uploaded_file_version
  type: int
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['prediction_file_version'])
    loadContents: true
- id: results
  type: File
  outputBinding:
    glob: results.json

baseCommand: python3
arguments:
- valueFrom: upload_file.py
- prefix: -f
  valueFrom: $(inputs.infile)
- prefix: -p
  valueFrom: $(inputs.parentid)
- prefix: -ui
  valueFrom: $(inputs.used_entity)
- prefix: -e
  valueFrom: $(inputs.executed_entity)
- prefix: -r
  valueFrom: results.json
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/synapseclient.txt

s:author:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5841-0198
  s:email: thomas.yu@sagebionetworks.org
  s:name: Thomas Yu

s:contributor:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5622-7998
  s:email: verena.chung@sagebase.org
  s:name: Verena Chung

s:codeRepository: https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates
s:license: https://spdx.org/licenses/Apache-2.0

$namespaces:
  s: https://schema.org/
