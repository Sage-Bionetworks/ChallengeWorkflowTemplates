#!/usr/bin/env cwl-runner
#
# Example sends validation emails to participants
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

inputs:
  - id: submissionId
    type: int
  - id: synapseConfig
    type: File
  - id: parentId
    type: string

arguments:
  - valueFrom: notifyEmail.py
  - valueFrom: $(inputs.submissionId)
    prefix: -s
  - valueFrom: $(inputs.synapseConfig.path)
    prefix: -c
  - valueFrom: $(inputs.parentId)
    prefix: -p

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: notifyEmail.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          import os
          parser = argparse.ArgumentParser()
          parser.add_argument("-s", "--submissionId", required=True, help="Submission ID")
          parser.add_argument("-c", "--synapseConfig", required=True, help="credentials file")
          parser.add_argument("-p","--parentId", required=True, help="Parent Id of participant folder")

          args = parser.parse_args()
          syn = synapseclient.Synapse(configPath=args.synapseConfig)
          syn.login()

          sub = syn.getSubmission(args.submissionId)
          userId = sub.userId
          evaluation = syn.getEvaluation(sub.evaluationId)

          subject = "Docker Submission Logs to '%s'!" % evaluation.name
          message = ["Hello %s,\n\n" % syn.getUserProfile(userId)['userName'],
                     "Your docker submission (%s) will have logs that can be found here: https://www.synapse.org/#!Synapse:%s !\n\n" % (sub.name, args.parentId),
                     "\nSincerely,\nChallenge Administrator"]
          syn.sendMessage(
            userIds=[userId],
            messageSubject=subject,
            messageBody="".join(message),
            contentType="text/html")
          
outputs: []
