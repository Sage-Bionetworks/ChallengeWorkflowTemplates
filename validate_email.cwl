#!/usr/bin/env cwl-runner
#
# Example sends validation emails to participants
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

          args = parser.parse_args()
          syn = synapseclient.Synapse(configPath=args.synapse_config)
          syn.login()

          sub = syn.getSubmission(args.submissionid)
          userid = sub.userId
          evaluation = syn.getEvaluation(sub.evaluationId)
          if args.status == "INVALID":
            subject = "Submission to '%s' invalid!" % evaluation.name
            message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
                       "Your submission (%s) is invalid, below are the invalid reasons:\n\n" % sub.name,
                       args.invalid,
                       "\n\nSincerely,\nChallenge Administrator"]
          else:
            subject = "Submission to '%s' accepted!" % evaluation.name
            message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
                       "Your submission (%s) is valid!\n\n" % sub.name,
                       "\nSincerely,\nChallenge Administrator"]
          syn.sendMessage(
            userIds=[userid],
            messageSubject=subject,
            messageBody="".join(message),
            contentType="text")
          
outputs:
- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )
