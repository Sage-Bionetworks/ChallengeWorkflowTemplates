#!/usr/bin/env cwl-runner
#
# Annotate an existing submission with a string value
# (variations can be written to pass long or float values)
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
  - id: annotation_values
    type: File
  - id: to_public
    type: boolean?
  - id: force
    type: boolean?
  - id: synapse_config
    type: File
  - id: previous_annotation_finished
    type: boolean?

arguments:
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: annotate-submission
  - valueFrom: $(inputs.submissionid)
  - valueFrom: $(inputs.annotation_values)
  - valueFrom: $(inputs.to_public)
    prefix: -p
  - valueFrom: $(inputs.force)
    prefix: -f

outputs:

- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )
