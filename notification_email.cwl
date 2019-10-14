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
  - id: parentid
    type: string

arguments:
  - valueFrom: notify_email.py
  - valueFrom: $(inputs.submissionid)
    prefix: -s
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: $(inputs.parentid)
    prefix: -p

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: notify_email.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          import os
          parser = argparse.ArgumentParser()
          parser.add_argument("-s", "--submissionid", required=True, help="Submission ID")
          parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
          parser.add_argument("-p","--parentid", required=True, help="Parent Id of participant folder")

          args = parser.parse_args()
          syn = synapseclient.Synapse(configPath=args.synapse_config)
          syn.login()

          sub = syn.getSubmission(args.submissionid)
          userid = sub.userId
          evaluation = syn.getEvaluation(sub.evaluationId)

          subject = "Docker Submission Logs to '%s'!" % evaluation.name
          message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
                     "Your docker submission (%s) will have logs that can be found here: https://www.synapse.org/#!Synapse:%s !\n\n" % (sub.name, args.parentid),
                     "\nSincerely,\nChallenge Administrator"]
          syn.sendMessage(
            userIds=[userid],
            messageSubject=subject,
            messageBody="".join(message),
            contentType="text")
          
outputs: []
