#!/usr/bin/env cwl-runner
#
# Writes a json file based on an annotation key value pair
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
baseCommand: [python, write.py]

hints:
  DockerRequirement:
    dockerPull: python:3.7

inputs:
  - id: key
    type: string
    inputBinding:
      prefix: -k

  - id: value
    type: string
    inputBinding:
      prefix: -v

  - id: output
    type: string
    default: results.json
    inputBinding:
      prefix: -r

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: write.py
        entry: |
          #!/usr/bin/env python
          import argparse
          import json

          parser = argparse.ArgumentParser()
          parser.add_argument("-r", "--results", required=True, help="annotation json")
          parser.add_argument("-k", "--key", required=True, help="Annotation key")
          parser.add_argument("-v", "--value", help="Annotation value")
          args = parser.parse_args()

          result = {args.key: args.value}
          with open(args.results, 'w') as o:
              o.write(json.dumps(result))

outputs:

  - id: results
    type: File
    outputBinding:
      glob: results.json  