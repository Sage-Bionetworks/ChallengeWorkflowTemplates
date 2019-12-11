#!/usr/bin/env cwl-runner
#
# Annotate an existing submission with a string value
# (variations can be written to pass long or float values)
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: challengeutils

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn18058986/challengeutils:develop

requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: submissionid
    type: int
  - id: annotation_values
    type: File
  - id: to_public
    type: boolean?
  - id: force_change_annotation_acl
    type: boolean?
  - id: synapse_config
    type: File
  - id: previous_annotation_finished
    type: boolean?

arguments:
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: annotatesubmission
  - valueFrom: $(inputs.submissionid)
  - valueFrom: $(inputs.annotation_values)
  - valueFrom: $(inputs.to_public)
    prefix: -p
  - valueFrom: $(inputs.force_change_annotation_acl)
    prefix: -f

outputs:

- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )

