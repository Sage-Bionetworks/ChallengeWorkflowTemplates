#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Download leading submission
doc: >
  Download the current lead submission based on a cutoff.

inputs:
- id: submissionid
  type: int
  inputBinding:
    prefix: -i
- id: synapse_config
  type: File
- id: status
  type: string
  inputBinding:
    prefix: -s
- id: cutoff_annotation
  type: string
  default: met_cutoff
  inputBinding:
    prefix: -a

outputs:
- id: output
  type: File?
  outputBinding:
    glob: previous_submission.csv

baseCommand:
- challengeutils
arguments:
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- download-current-lead-submission

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/challengeutils.txt

s:author:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-0326-7494
  s:email: andrew.lamb@sagebase.org
  s:name: Andrew Lamb

s:contributor:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5622-7998
  s:email: verena.chung@sagebase.org
  s:name: Verena Chung

s:codeRepository: https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates
s:license: https://spdx.org/licenses/Apache-2.0

$namespaces:
  s: https://schema.org/
