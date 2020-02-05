#!/usr/bin/env cwl-runner
#
# Sends validation emails to participants
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v1.9.2

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

arguments:
  - valueFrom: validation_email.py
  - valueFrom: $(inputs.submissionid)
    prefix: -s
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: $(inputs.status)
    prefix: --status
  - valueFrom: $(inputs.invalid_reasons)
    prefix: -i
  - valueFrom: $(inputs.errors_only)
    prefix: --errors_only


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
          if teamid is not None:
            name = syn.getTeam(participantid)['name']
          else:
            participantid = sub.userId
            name = syn.getUserProfile(participantid)['userName']
          evaluation = syn.getEvaluation(sub.evaluationId)
          message = subject = ""
          if args.status == "INVALID":
            subject = "Submission to '%s' invalid!" % evaluation.name
            message = ["Hello %s,\n\n" % name,
                       "Your submission (%s) is invalid, below are the invalid reasons:\n\n" % sub.name,
                       args.invalid,
                       "\n\nSincerely,\nChallenge Administrator"]
          elif not args.errors_only:
            subject = "Submission to '%s' accepted!" % evaluation.name
            message = ["Hello %s,\n\n" % name,
                       "Your submission (%s) is valid!\n\n" % sub.name,
                       "\nSincerely,\nChallenge Administrator"]
          if message:
            syn.sendMessage(
              userIds=[participantid],
              messageSubject=subject,
              messageBody="".join(message),
              contentType="text")

outputs:
- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )