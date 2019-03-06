#!/usr/bin/env cwl-runner
#
# Authors: Andrew Lamb

cwlVersion: v1.0
class: CommandLineTool
baseCommand: [challengeutils download_current_lead_submission]

hints:
  DockerRequirement:
    dockerPull: challengeutils

inputs:

  - id: submissionid
    type: int
    inputBinding:
      prefix: -i
      
  - id: synapse_config
    type: File
    inputBinding:
      prefix: -c
    
  - id: status
    type: string
    inputBinding:
      prefix: -s

  - id: cutoff_annotation
    type: string?
    inputBinding:
      prefix: -a
   
outputs:

  - id: output
    type: File?
    outputBinding:
      glob: "previous_submission.csv"
