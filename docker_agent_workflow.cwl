#!/usr/bin/env cwl-runner
#
# Sample workflow
# Inputs:
#   submissionId: ID of the Synapse submission to process
#   adminUploadSynId: ID of a folder accessible only to the submission queue administrator
#   submitterUploadSynId: ID of a folder accessible to the submitter
#   workflowSynapseId:  ID of the Synapse entity containing a reference to the workflow file(s)
#
cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement

inputs:
  - id: submissionId
    type: int
  - id: adminUploadSynId
    type: string
  - id: submitterUploadSynId
    type: string
  - id: workflowSynapseId
    type: string
  - id: synapseConfig
    type: File

# there are no output at the workflow engine level.  Everything is uploaded to Synapse
outputs: []

steps:

  notify_participants:
    run: notification_email.cwl
    in:
      - id: submissionId
        source: "#submissionId"
      - id: synapseConfig
        source: "#synapseConfig"
      - id: parentId
        source: "#submitterUploadSynId"
    out: []

  get_docker_submission:
    run: get_submission_docker.cwl
    in:
      - id: submissionId
        source: "#submissionId"
      - id: synapseConfig
        source: "#synapseConfig"
    out:
      - id: dockerRepository
      - id: dockerDigest
      - id: entityId
      
  validate_docker:
    run: validate_docker.cwl
    in:
      - id: dockerRepository
        source: "#get_docker_submission/dockerRepository"
      - id: dockerDigest
        source: "#get_docker_submission/dockerDigest"
      - id: synapseConfig
        source: "#synapseConfig"
    out:
      - id: results
      - id: status
      - id: invalidReasons

  annotate_validation_with_output:
    run: annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#validate_docker/results"
      - id: to_public
        valueFrom: "true"
      - id: force_change_annotation_acl
        valueFrom: "true"
      - id: synapse_config
        source: "#synapseConfig"
    out: []
 
  get_docker_config:
    run: get_docker_config.cwl
    in:
      - id: synapseConfig
        source: "#synapseConfig"
    out: 
      - id: dockerRegistry
      - id: dockerAuth

  run_docker:
    run: run_docker.cwl
    in:
      - id: dockerRepository
        source: "#get_docker_submission/dockerRepository"
      - id: dockerDigest
        source: "#get_docker_submission/dockerDigest"
      - id: submissionId
        source: "#submissionId"
      - id: dockerRegistry
        source: "#get_docker_config/dockerRegistry"
      - id: dockerAuth
        source: "#get_docker_config/dockerAuth"
      - id: status
        source: "#validate_docker/status"
      - id: parentId
        source: "#submitterUploadSynId"
      - id: synapseConfig
        source: "#synapseConfig"
    out:
      - id: predictions

  upload_results:
    run: upload_to_synapse.cwl
    in:
      - id: infile
        source: "#run_docker/predictions"
      - id: parentId
        source: "#adminUploadSynId"
      - id: usedEntity
        source: "#get_docker_submission/entityId"
      - id: executedEntity
        source: "#workflowSynapseId"
      - id: synapseConfig
        source: "#synapseConfig"
    out:
      - id: uploadedFileId
      - id: uploadedFileVersion
      - id: results

  annotate_docker_upload_results:
    run: annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#upload_results/results"
      - id: to_public
        valueFrom: "true"
      - id: force_change_annotation_acl
        valueFrom: "true"
      - id: synapse_config
        source: "#synapseConfig"
    out: []

  validation:
    run: validate.cwl
    in:
      - id: inputfile
        source: "#run_docker/predictions"
    out:
      - id: results
      - id: status
      - id: invalidReasons
  
  validation_email:
    run: validate_email.cwl
    in:
      - id: submissionId
        source: "#submissionId"
      - id: synapseConfig
        source: "#synapseConfig"
      - id: status
        source: "#validation/status"
      - id: invalidReasons
        source: "#validation/invalidReasons"

    out: []

  annotate_validation_with_output:
    run: annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#validation/results"
      - id: to_public
        valueFrom: "true"
      - id: force_change_annotation_acl
        valueFrom: "true"
      - id: synapse_config
        source: "#synapseConfig"
    out: []

  download_goldstandard:
    run: download_from_synapse.cwl
    in:
      - id: synapseid
        #This is a dummy syn id
        valueFrom: "syn8695042"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath

  scoring:
    run: score.cwl
    in:
      - id: inputfile
        source: "#run_docker/predictions"
      - id: status 
        source: "#validation/status"
      - id: goldstandard
        source: "#download_goldstandard/filepath"
    out:
      - id: results
      
  score_email:
    run: score_email.cwl
    in:
      - id: submissionId
        source: "#submissionId"
      - id: synapseConfig
        source: "#synapseConfig"
      - id: results
        source: "#scoring/results"
    out: []

  annotate_submission_with_output:
    run: annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#scoring/results"
      - id: to_public
        valueFrom: "true"
      - id: force_change_annotation_acl
        valueFrom: "true"
      - id: synapse_config
        source: "#synapseConfig"
    out: []
 