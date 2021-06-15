#!/usr/bin/env cwl-runner
#
# Submit to challenge
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
baseCommand: synapse

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.3.1

inputs:
  - id: submission_file
    type: string
  - id: submissionid
    type: int
  - id: synapse_config
    type: File
  - id: evaluationid
    type: string

arguments:
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: submit
  - valueFrom: $(inputs.evaluationid)
    prefix: --evalID
  - valueFrom: $(inputs.submission_file)
    prefix: --id
  - valueFrom: $(inputs.submissionid)
    prefix: --name

requirements:
  - class: InlineJavascriptRequirement

outputs: []
