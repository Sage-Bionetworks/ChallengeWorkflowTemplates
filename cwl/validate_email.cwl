#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Email validation results
doc: >
  Send an email of the validation results back to the submitter and, if on a
  submission team, their teammates.

requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entryname: validation_email.py
    entry: |
      #!/usr/bin/env python
      import synapseclient
      import argparse
      import json
      import os
      parser = argparse.ArgumentParser()
      parser.add_argument("-s", "--submissionid", required=True, help="Submission ID")
      parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
      parser.add_argument("--status", required=True, help="Prediction File Status")
      parser.add_argument("-i","--invalid", required=True, help="Invalid reasons")
      parser.add_argument("--errors_only", action="store_true", help="Only send email if errors found")

      args = parser.parse_args()
      syn = synapseclient.Synapse(configPath=args.synapse_config)
      syn.login()

      sub = syn.getSubmission(args.submissionid)
      participantid = sub.get("teamId")
      if participantid is not None:
        name = syn.getTeam(participantid)['name']
      else:
        participantid = sub.userId
        name = syn.getUserProfile(participantid)['userName']
      evaluation = syn.getEvaluation(sub.evaluationId)
      message = subject = ""
      if args.status == "INVALID":
        subject = "Submission to '%s' invalid!" % evaluation.name
        message = ["Hello %s,\n\n" % name,
                   "Your submission (id: %s) is invalid, below are the invalid reasons:\n\n" % sub.id,
                   args.invalid,
                   "\n\nSincerely,\nChallenge Administrator"]
      elif not args.errors_only:
        subject = "Submission to '%s' accepted!" % evaluation.name
        message = ["Hello %s,\n\n" % name,
                   "Your submission (id: %s) is valid!\n\n" % sub.id,
                   "\nSincerely,\nChallenge Administrator"]
      if message:
        syn.sendMessage(
          userIds=[participantid],
          messageSubject=subject,
          messageBody="".join(message))

inputs:
- id: submissionid
  type: int
- id: synapse_config
  type: File
- id: status
  type: string
- id: invalid_reasons
  type: string
- id: errors_only
  type: boolean?

outputs:
- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )

baseCommand: python3
arguments:
- valueFrom: validation_email.py
- prefix: -s
  valueFrom: $(inputs.submissionid)
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- prefix: --status
  valueFrom: $(inputs.status)
- prefix: -i
  valueFrom: $(inputs.invalid_reasons)
- prefix: --errors_only
  valueFrom: $(inputs.errors_only)

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/synapseclient.txt

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