#!/usr/bin/env cwl-runner
#
# Example validate submission file
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: [python, validate.py]

hints:
  DockerRequirement:
    dockerPull: python:3.9-slim-buster

inputs:

  - id: entity_type
    type: string
    inputBinding:
      prefix: -e

  - id: inputfile
    type: File?
    inputBinding:
      prefix: -s

  - id: goldstandard
    type: File?
    inputBinding:
      prefix: -g

  - id: output
    type: string?
    default: results.json
    inputBinding:
      prefix: -r

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: validate.py
        entry: |
          #!/usr/bin/env python
          import argparse
          import json
          parser = argparse.ArgumentParser()
          parser.add_argument("-r", "--results", required=True, help="validation results")
          parser.add_argument("-e", "--entity_type", required=True, help="synapse entity type downloaded")
          parser.add_argument("-s", "--submission_file", help="Submission File")
          parser.add_argument("-g", "--goldstandard", help="Goldstandard for scoring")

          args = parser.parse_args()
          
          if args.submission_file is None:
              prediction_file_status = "INVALID"
              invalid_reasons = ['Expected FileEntity type but found ' + args.entity_type]
          else:
              with open(args.submission_file,"r") as sub_file:
                  message = sub_file.read()
              invalid_reasons = []
              prediction_file_status = "VALIDATED"
              if not message.startswith("test"):
                  invalid_reasons.append("Submission must have test column")
                  prediction_file_status = "INVALID"
          result = {'submission_errors': "\n".join(invalid_reasons),
                    'submission_status': prediction_file_status}
          with open(args.results, 'w') as o:
              o.write(json.dumps(result))
     
outputs:

  - id: results
    type: File
    outputBinding:
      glob: $(inputs.output)

  - id: status
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['submission_status'])

  - id: invalid_reasons
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['submission_errors'])
