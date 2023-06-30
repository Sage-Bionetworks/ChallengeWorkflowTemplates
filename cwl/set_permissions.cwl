#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Set Synapse permissions
doc: >
  Set the permission level for the given Synapse entity; a common use case
  would be to give the submitter `download` permissions to their log files
  (by default, only the creator, aka the infrastructure person, has access).

inputs:
- id: entityid
  type: string
- id: principalid
  type: string
- id: permissions
  type: string
- id: synapse_config
  type: File

outputs: []

baseCommand: challengeutils
arguments:
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- valueFrom: set-entity-acl
- valueFrom: $(inputs.entityid)
- valueFrom: $(inputs.principalid)
- valueFrom: $(inputs.permissions)

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
