#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
doc: Run a Docker submission.

requirements:
- class: InitialWorkDirRequirement
  listing:
  - $(inputs.docker_script)
- class: InlineJavascriptRequirement

inputs:
- id: submissionid
  type: int
- id: docker_repository
  type: string
  default: ''
- id: docker_digest
  type: string
  default: ''
- id: parentid
  type: string
- id: synapse_config
  type: File
- id: input_dir
  type: string
- id: docker_script
  type: File
- id: memory_limit
  type: string?
  inputBinding:
    prefix: --container_memory_limit
- id: swap_limit
  type: string?
  inputBinding:
    prefix: --container_memory_swap_limit
- id: time_limit
  type: int?
  inputBinding:
    prefix: --container_time_limit
- id: store
  type: boolean?

outputs:
- id: predictions
  type: File?
  outputBinding:
    glob: predictions.csv
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

baseCommand: python3
arguments:
- valueFrom: $(inputs.docker_script.path)
- prefix: -s
  valueFrom: $(inputs.submissionid)
- prefix: --docker_repository
  valueFrom: $(inputs.docker_repository)
- prefix: --docker_digest
  valueFrom: $(inputs.docker_digest)
- prefix: --store
  valueFrom: $(inputs.store)
- prefix: --parentid
  valueFrom: $(inputs.parentid)
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- prefix: -i
  valueFrom: $(inputs.input_dir)
- prefix: -m
  valueFrom: $(inputs.memory_limit)
- prefix: -t
  valueFrom: $(inputs.time_limit)

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
