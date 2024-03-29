#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Validate predictions file

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

outputs:
- id: results
  type: File
  outputBinding:
    glob: $(inputs.output)
- id: status
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['submission_status'])
    loadContents: true
- id: invalid_reasons
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['submission_errors'])
    loadContents: true

baseCommand:
- python
- validate.py

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/python.txt

s:author:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5841-0198
  s:email: thomas.yu@sagebionetworks.org
  s:name: Thomas Yu

s:contributor:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-0326-7494
  s:email: andrew.lamb@sagebase.org
  s:name: Andrew Lamb

- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5622-7998
  s:email: verena.chung@sagebase.org
  s:name: Verena Chung

s:codeRepository: https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates
s:license: https://spdx.org/licenses/Apache-2.0

$namespaces:
  s: https://schema.org/