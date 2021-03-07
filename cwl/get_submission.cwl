#!/usr/bin/env cwl-runner
#
# Download a submitted file from Synapse and return the downloaded file
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
baseCommand: challengeutils

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/challengeutils:v4.0.1

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
  - valueFrom: download-submission
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

  - id: evaluation_id
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['evaluation_id'])

  - id: results
    type: File
    outputBinding:
      glob: results.json


