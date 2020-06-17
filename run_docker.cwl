#!/usr/bin/env cwl-runner
#
# Runs Docker Submission
#

$namespaces:
  s: https://schema.org/

s:author:
  - class: s:Person
    s:identifier: https://orcid.org/0000-0002-5841-0198
    s:email: thomas.yu@sagebionetworks.org
    s:name: Thomas Yu

s:contributor:
  - class: s:Person
    s:email: verena.chung@sagebase.org
    s:name: Verena Chung

cwlVersion: v1.0
class: CommandLineTool
baseCommand: python3

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

arguments: 
  - valueFrom: $(inputs.docker_script.path)
  - valueFrom: $(inputs.submissionid)
    prefix: -s
  - valueFrom: $(inputs.docker_repository)
    prefix: -p
  - valueFrom: $(inputs.docker_digest)
    prefix: -d
  - valueFrom: $(inputs.status)
    prefix: --status
  - valueFrom: $(inputs.parentid)
    prefix: --parentid
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: $(inputs.input_dir)
    prefix: -i

requirements:
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.docker_script)
      - entryname: .docker/config.json
        entry: |
          {"auths": {"$(inputs.docker_registry)": {"auth": "$(inputs.docker_authentication)"}}}
  - class: InlineJavascriptRequirement

outputs:
  predictions:
    type: File
    outputBinding:
      glob: output/predictions.csv