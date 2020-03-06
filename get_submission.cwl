#!/usr/bin/env cwl-runner
#
# Download a submitted file from Synapse and return the downloaded file
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: challengeutils

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn18058986/challengeutils:v1.3.0

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

  - id: docker_repository
    type: string?
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['docker_repository'])

  - id: docker_digest
    type: string?
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['docker_digest'])

  - id: entity_type
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['entity_type'])

  - id: entity_id
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['entity_id'])

  - id: results
    type: File
    outputBinding:
      glob: results.json


