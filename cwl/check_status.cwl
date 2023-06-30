#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: ExpressionTool

label: Check submission status
doc: >
  Check the current submission status; if INVALID, throw an exception to
  end the workflow.

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: status
  type: string
- id: previous_annotation_finished
  type: boolean?
- id: previous_email_finished
  type: boolean?

outputs:
- id: finished
  type: boolean
expression: |2

  ${
    if(inputs.status == "INVALID"){
      throw 'invalid submission';
    } else {
      return {finished: true};
    }
  }

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