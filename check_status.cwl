#!/usr/bin/env cwl-runner
#
# Example sends validation emails to participants
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

inputs:

  - id: status
    type: string
  - id: previous_annotation_finished
    type: boolean?
  - id: previous_email_finished
    type: boolean?

arguments:
  - valueFrom: check_status.py
  - valueFrom: $(inputs.status)
    prefix: --status

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: check_status.py
        entry: |
          #!/usr/bin/env python
          import argparse
          parser = argparse.ArgumentParser()
          parser.add_argument("--status", required=True, help="Prediction File Status")
          args = parser.parse_args()
          if args.status == "INVALID":
            raise ValueError("INVALID PREDICTION FILE")
          
outputs:
- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )
