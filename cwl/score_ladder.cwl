#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Ladder-style scoring
doc: >
  Score a submission using the "ladder" approach, that is, by taking into
  account a previous submission file.

requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entryname: score.py
    entry: |
      #!/usr/bin/env python
      import argparse
      import json
      parser = argparse.ArgumentParser()
      parser.add_argument("-f", "--submissionfile", required=True, help="Submission File")
      parser.add_argument("-p", "--previousfile", required=True, help="Previous Submission File")
      parser.add_argument("-r", "--results", required=True, help="Scoring results")
      parser.add_argument("-g", "--goldstandard", required=True, help="Goldstandard for scoring")

      args = parser.parse_args()
      score = 3
      prediction_file_status = "SCORED"
      result = {'score':score,
                'submission_status': prediction_file_status}
      with open(args.results, 'w') as o:
        o.write(json.dumps(result))

inputs:
- id: inputfile
  type: File
- id: previousfile
  type: File
- id: goldstandard
  type: File
- id: check_validation_finished
  type: boolean?

outputs:
- id: results
  type: File
  outputBinding:
    glob: results.json

baseCommand: python
arguments:
- valueFrom: score.py
- prefix: -f
  valueFrom: $(inputs.inputfile.path)
- prefix: -p
  valueFrom: $(inputs.previousfile.path)
- prefix: -g
  valueFrom: $(inputs.goldstandard.path)
- prefix: -r
  valueFrom: results.json

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/python.txt

s:author:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-0326-7494
  s:email: andrew.lamb@sagebase.org
  s:name: Andrew Lamb

s:contributor:
- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5841-0198
  s:email: thomas.yu@sagebionetworks.org
  s:name: Thomas Yu

- class: s:Person
  s:identifier: https://orcid.org/0000-0002-5622-7998
  s:email: verena.chung@sagebase.org
  s:name: Verena Chung

s:codeRepository: https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates
s:license: https://spdx.org/licenses/Apache-2.0

$namespaces:
  s: https://schema.org/