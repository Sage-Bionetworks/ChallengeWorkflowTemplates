#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Download submission from Synapse

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: submissionid
  type: int
- id: synapse_config
  type: File

outputs:
- id: filepath
  type: File?
  outputBinding:
    glob: $("submission-"+inputs.submissionid)
- id: docker_repository
  type: string?
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['docker_repository'])
    loadContents: true
- id: docker_digest
  type: string?
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['docker_digest'])
    loadContents: true
- id: entity_type
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['entity_type'])
    loadContents: true
- id: entity_id
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['entity_id'])
    loadContents: true
- id: evaluation_id
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['evaluation_id'])
    loadContents: true
- id: results
  type: File
  outputBinding:
    glob: results.json

baseCommand: challengeutils
arguments:
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- valueFrom: download-submission
- valueFrom: $(inputs.submissionid)
- prefix: --output
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
