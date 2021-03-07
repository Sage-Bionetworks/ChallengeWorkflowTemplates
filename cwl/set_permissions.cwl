#!/usr/bin/env cwl-runner
#
# Sets permissions.
# This tool was created so that download permissions can be set
# on the log folder of the submission given to the admin team.
# When the challenge is run by a service account, only the service account
# has access to the log folder.
#
$namespaces:
  s: https://schema.org/

s:author:
  - class: s:Person
    s:identifier: https://orcid.org/0000-0002-5841-0198
    s:email: thomas.yu@sagebionetworks.org
    s:name: Thomas Yu

cwlVersion: v1.0
class: CommandLineTool
baseCommand: challengeutils

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/challengeutils:v4.0.1

inputs:
  - id: entityid
    type: string
  - id: principalid
    type: string
  - id: permissions
    type: string
  - id: synapse_config
    type: File

arguments:
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: set-entity-acl
  - valueFrom: $(inputs.entityid)
  - valueFrom: $(inputs.principalid)
  - valueFrom: $(inputs.permissions)

outputs: []
