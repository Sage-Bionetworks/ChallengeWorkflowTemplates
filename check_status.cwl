#!/usr/bin/env cwl-runner
#
# Throws invalid error which invalidates the workflow
#

$namespaces:
  s: https://schema.org/

s:author:
  - class: s:Person
    s:identifier: https://orcid.org/0000-0002-5841-0198
    s:email: thomas.yu@sagebionetworks.org
    s:name: Thomas Yu

cwlVersion: v1.0
class: ExpressionTool

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

requirements:
  - class: InlineJavascriptRequirement

expression: |

  ${
    if(inputs.status == "INVALID"){
      throw 'invalid submission';
    } else {
      return {finished: true};
    }
  }


