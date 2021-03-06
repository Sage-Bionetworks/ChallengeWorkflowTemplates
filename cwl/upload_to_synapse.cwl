#!/usr/bin/env cwl-runner
#
# Uploads a file to Synapse and return the ID
# param's include the parentId (project or folder) to which the file is to be uploaded
# and the provenance information for the file
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
    dockerPull: sagebionetworks/synapsepythonclient:v2.3.0

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

arguments:
  - valueFrom: upload_file.py
  - valueFrom: $(inputs.infile)
    prefix: -f
  - valueFrom: $(inputs.parentid)
    prefix: -p
  - valueFrom: $(inputs.used_entity)
    prefix: -ui
  - valueFrom: $(inputs.executed_entity)
    prefix: -e
  - valueFrom: results.json
    prefix: -r
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c

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
     
outputs:
  - id: uploaded_fileid
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_fileid'])
  
  - id: uploaded_file_version
    type: int
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_file_version'])
  
  - id: results
    type: File
    outputBinding:
      glob: results.json   
