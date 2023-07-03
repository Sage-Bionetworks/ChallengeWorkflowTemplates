#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Annotate submission
doc: >
  Annotate an existing submission with string values (variations can be
  written to also pass along other types, such as long or float).

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

outputs:
- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )

baseCommand: challengeutils
arguments:
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- valueFrom: annotate-submission
- valueFrom: $(inputs.submissionid)
- valueFrom: $(inputs.annotation_values)
- prefix: -p
  valueFrom: $(inputs.to_public)
- prefix: -f
  valueFrom: $(inputs.force)

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/challengeutils.txt

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
