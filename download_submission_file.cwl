#!/usr/bin/env cwl-runner
#
# Download a submitted file from Synapse and return the downloaded file
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: challengeutils

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/challengeutils:develop

requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: submissionid
    type: int
  - id: synapse_config
    type: File

arguments:
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: downloadsubmission
  - valueFrom: $(inputs.submissionid)
  - valueFrom: results.json
    prefix: --output
     
outputs:
  - id: filepath
    type: File?
    outputBinding:
      glob: $("submission-"+inputs.submissionid)

  - id: results
    type: File
    outputBinding:
      glob: results.json

  - id: entity_type
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['entity_type'])

  - id: entity
    type:
      type: record
      fields:
      - name: id
        type: string
        outputBinding:
          glob: results.json
          loadContents: true
          outputEval: $(JSON.parse(self[0].contents)['entity_id'])
      - name: version
        type: int
        outputBinding:
          glob: results.json
          loadContents: true
          outputEval: $(JSON.parse(self[0].contents)['entity_version'])

