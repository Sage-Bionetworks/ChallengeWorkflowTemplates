#!/usr/bin/env cwl-runner
#
# Sample workflow
# Inputs:
#   submissionId: ID of the Synapse submission to process
#   adminUploadSynId: ID of a folder accessible only to the submission queue administrator
#   submitterUploadSynId: ID of a folder accessible to the submitter
#   workflowSynapseId:  ID of the Synapse entity containing a reference to the workflow file(s)
#   synapseConfig: ~/.synapseConfig file that has your Synapse credentials
#
cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

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
  download_current_submission:
    run: download_submission_file.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath
      - id: entity
      - id: entity_type 
      
  validation:
    run: validate2.cwl
    in:
      - id: inputfile
        source: "#download_current_submission/filepath"
      - id: goldstandard
        source: "#download_goldstandard/filepath"
      - id: entity_type
        source: "#download_current_submission/entity_type"
    out:
      - id: results
      - id: status
      - id: invalid_reasons
      

  validation_email:
    run: validate_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status
        source: "#validation/status"
      - id: invalid_reasons
        source: "#validation/invalid_reasons"

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
    out: [finished]
    
  download_previous_submission:
    run: download_current_lead_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status 
        source: "#validation/status"
    out:
      - id: output

  download_goldstandard:
    run: download_from_synapse.cwl
    in:
########## Must supply correct synapse id here here #################
      - id: synapseid
        valueFrom: "syn1"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath

  scoring:
    run: score2.cwl
    in:
      - id: inputfile
        source: "#download_current_submission/filepath"
      - id: status 
        source: "#validation/status"
      - id: goldstandard
        source: "#download_goldstandard/filepath"
      - id: previousfile
        source: "#download_previous_submission/output"
    out:
      - id: results
      
  score_email:
    run: score_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
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
      - id: previous_annotation_finished
        source: "#annotate_validation_with_output/finished"
    out: [finished]
 
