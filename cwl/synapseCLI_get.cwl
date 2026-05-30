#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
doc: |
    Use the synapse CLI to download a file from Synapse.

    Note: synapseclient v4 creates a manifest file by default, as
    well as cache directories. `--manifest suppress` is used to 
    prevent the manifest file, and the outputEval for the filepath
    output is used to filter out the cache directories.

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: .synapseConfig
        entry: $(inputs.synapse_config)

inputs:
  - id: synapse_config
    type: File
  - id: synapseid
    type: string

outputs:
  - id: filepath
    type: File
    outputBinding:
      glob: '*'
      outputEval: |
        ${
          return self.filter(function(f) {
            return f.class === 'File';
          })[0];
        }

baseCommand: synapse
arguments:
  - valueFrom: get
  - valueFrom: $(inputs.synapseid)
  - valueFrom: "--manifest"
  - valueFrom: suppress

hints:
  DockerRequirement:
    dockerPull: 
      $include: ../versions/synapseclient.txt