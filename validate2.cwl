#!/usr/bin/env cwl-runner
#
# Example validate submission file
#
# This version of validate.cwl uses the gold standard to test the input file

cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

inputs:
  - id: inputfile
    type: File
  - id: goldstandard
    type: File

arguments:
  - valueFrom: validate.py
  - valueFrom: $(inputs.inputfile.path)
    prefix: -s
  - valueFrom: results.json
    prefix: -r
  - valueFrom: $(inputs.goldstandard.path)
    prefix: -g

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: validate.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import os
          import json
          parser = argparse.ArgumentParser()
          parser.add_argument("-s", "--submission_file", required=True, help="Submission File")
          parser.add_argument("-r", "--results", required=True, help="validation results")
          parser.add_argument("-g", "--goldstandard", required=True, help="Goldstandard for scoring")

          args = parser.parse_args()
          with open(args.submission_file,"r") as sub_file:
            message = sub_file.read()
          invalid_reasons = []
          prediction_file_status = "VALIDATED"
          if not message.startswith("test"):
            invalid_reasons.append("Submission must have test column")
            prediction_file_status = "INVALID"
          result = {'prediction_file_errors':"\n".join(invalid_reasons),'prediction_file_status':prediction_file_status}
          with open(args.results, 'w') as o:
            o.write(json.dumps(result))
     
outputs:

  - id: results
    type: File
    outputBinding:
      glob: results.json   

  - id: status
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_file_status'])

  - id: invalid_reasons
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_file_errors'])