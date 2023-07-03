#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Run Docker submission

requirements:
- class: InitialWorkDirRequirement
  listing:
  - $(inputs.docker_script)
  - entryname: .docker/config.json
    entry: |
      {"auths": {"$(inputs.docker_registry)": {"auth": "$(inputs.docker_authentication)"}}}
- class: InlineJavascriptRequirement

inputs:
- id: submissionid
  type: int
- id: docker_repository
  type: string
- id: docker_digest
  type: string
- id: docker_registry
  type: string
- id: docker_authentication
  type: string
- id: parentid
  type: string
- id: status
  type: string
- id: synapse_config
  type: File
- id: input_dir
  type: string
- id: docker_script
  type: File

outputs:
  predictions:
    type: File
    outputBinding:
      glob: output/predictions.csv

baseCommand: python3
arguments:
- valueFrom: $(inputs.docker_script.path)
- prefix: -s
  valueFrom: $(inputs.submissionid)
- prefix: -p
  valueFrom: $(inputs.docker_repository)
- prefix: -d
  valueFrom: $(inputs.docker_digest)
- prefix: --status
  valueFrom: $(inputs.status)
- prefix: --parentid
  valueFrom: $(inputs.parentid)
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- prefix: -i
  valueFrom: $(inputs.input_dir)

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
