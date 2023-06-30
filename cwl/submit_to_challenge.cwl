#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Submit to challenge

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: submission_file
  type: string
- id: submissionid
  type: int
- id: synapse_config
  type: File
- id: evaluationid
  type: string

outputs: []

baseCommand: synapse
arguments:
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- valueFrom: submit
- prefix: --evalID
  valueFrom: $(inputs.evaluationid)
- prefix: --id
  valueFrom: $(inputs.submission_file)
- prefix: --name
  valueFrom: $(inputs.submissionid)

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
