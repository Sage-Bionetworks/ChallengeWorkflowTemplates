#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Validate Docker submission

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: submissionid
  type: int
- id: synapse_config
  type: File

outputs:
- id: results
  type: File
  outputBinding:
    glob: results.json
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

baseCommand: challengeutils
arguments:
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- valueFrom: validate-docker
- valueFrom: $(inputs.submissionid)
- prefix: -o
  valueFrom: results.json

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/challengeutils.txt

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
