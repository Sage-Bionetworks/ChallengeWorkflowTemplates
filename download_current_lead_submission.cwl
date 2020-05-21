#!/usr/bin/env cwl-runner
#
# Downloads current lead submission based on a cutoff
#
# Authors: Andrew Lamb

cwlVersion: v1.0
class: CommandLineTool
baseCommand:

- challengeutils

arguments:

- valueFrom: $(inputs.synapse_config.path)
  prefix: -c

- download_current_lead_submission


hints:
  DockerRequirement:
    dockerPull: sagebionetworks/challengeutils:v2.1.0

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
    default: "met_cutoff"
    inputBinding:
      prefix: -a
   
outputs:

  - id: output
    type: File?
    outputBinding:
      glob: "previous_submission.csv"
