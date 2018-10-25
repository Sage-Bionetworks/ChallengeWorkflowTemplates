#!/usr/bin/env cwl-runner
#
# Example score submission file
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

inputs:
  - id: inputfile
    type: File
  - id: goldstandard
    type: File
  - id: status
    type: string

arguments:
  - valueFrom: score.py
  - valueFrom: $(inputs.inputfile.path)
    prefix: -f
  - valueFrom: $(inputs.status)
    prefix: -s
  - valueFrom: $(inputs.goldstandard.path)
    prefix: -g
  - valueFrom: results.json
    prefix: -r

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: score.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import os
          import json
          parser = argparse.ArgumentParser()
          parser.add_argument("-f", "--submissionFile", required=True, help="Submission File")
          parser.add_argument("-s", "--status", required=True, help="Submission status")
          parser.add_argument("-r", "--results", required=True, help="Scoring results")
          parser.add_argument("-g", "--goldstandard", required=True, help="Goldstandard for scoring")

          args = parser.parse_args()
          if args.status == "VALIDATED":
            predictionFileStatus = "SCORED"
            score = 3
          else:
            predictionFileStatus = args.status
            score = -1
          result = {'score':score,'predictionFileStatus':predictionFileStatus}
          with open(args.results, 'w') as o:
            o.write(json.dumps(result))
     
outputs:
  - id: results
    type: File
    outputBinding:
      glob: results.json