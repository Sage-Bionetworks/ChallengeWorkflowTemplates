# Challenge Workflow CWL Tools

## Authors
* [Thomas Yu](https://github.com/thomasyu888)
* [Verena Chung](https://github.com/vpchung)
* [Andrew Lamb](https://github.com/andrewelamb)

## Introduction

These are a collection of CWL tools used in the challenge infrastructure workflows that can be linked with the [Synapse Workflow Orchestrator](https://github.com/Sage-Bionetworks/SynapseWorkflowOrchestrator).  The workflows in this repository also leverage CWL tools in [cwl-tools-synapseclient](https://github.com/Sage-Bionetworks-Workflows/cwl-tool-synapseclient). There are three different challenge workflows:

1. **Data to Model**: Participants submit prediction files and these files are validated and scored.  Please see [data-to-model-challenge-workflow](https://github.com/Sage-Bionetworks-Challenges/data-to-model-challenge-workflow) to see how to use the CWL tool in the `cwl` folder.
1. **Model to Data**: Participants submit a docker container with their model, which then runs against internal data and a prediction file is generate.  This prediction file is then validated and scored. Please see [model-to-data-challenge-workflow](https://github.com/Sage-Bionetworks-Challenges/model-to-data-challenge-workflow) to see how to use the CWL tool in the `cwl` folder.
1. **Ladder Classic**: Participants submit prediction files but these files are compared against leading submissions.

This README will guide you to learn how to use these challenge templates.  Here are some example challenges that currently use these templates: 

* [CTD^2 Panacea Challenge](https://github.com/Sage-Bionetworks/CTDD-Panacea-Challenge)
* [RA2-DREAM-challenge](https://github.com/Sage-Bionetworks/RA2-dream-workflows)
* [CTD^2 BeatAML Challenge](https://github.com/Sage-Bionetworks/CTD2-BeatAML-Challenge)
* [Allen Institute Cell Lineage Reconstruction DREAM Challenge](https://github.com/Sage-Bionetworks/Allen-DREAM-Challenge)
* [Metadata Automation DREAM Challenge](https://github.com/Sage-Bionetworks/metadata-automation-challenge/tree/master/workflow)
* [EHR DREAM Challenge](https://github.com/Sage-Bionetworks/EHR-challenge)

Please note that these examples linked above do not contain all the tools you see in this repository, but instead the `run` steps link out to specific tagged versions of these tools.  This specific step below is using `v3.0` of the `get_submission.cwl` tool.

```
download_submission:
  run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.0/cwl/get_submission.cwl
...
```


## CWL Tools

### Annotation
```
annotate_submission:
  run: https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates/tree/v3.0/cwl/annotate_submission.cwl
  in:
    - id: submissionid
      source: "#submissionId"
    - id: annotation_values
      source: "#validate_docker/results"
    - id: to_public
      default: true
    - id: force
      default: true
    - id: synapse_config
      source: "#synapseConfig"
  out: []
```
The values `to_public` and `force` can be `true` or `false`.  `to_public` controls the ACL of each annotation key passed in during the annotation step, while `force` allows for the same annotation key to change ACLs.  For instance, if the original annotations had annotation `A` that was private, and annotation `A` was passed in again as a public annotation, this would fail the pipeline.  However, passing in `force` as `true` would allow for this change.

### Messages

`{notificiation,validate,score}_email.cwl` are general templates for submission emails.  You may edit the body of the email to change the subject title and message sent.

If you would not like to email participants, simply comment these steps out.  These workflow steps are required for challenges because participants should only be receiving pertinent information back from the scoring harness.  If the scoring code breaks, it is the responsibility of the administrator to receive notifications and fix the code.

### Running Docker Submission: run_docker.cwl/run_docker.py

Please note that the this run docker step has access to your local file system, but the output file must be written to the current working directory of the CWL environment such that CWL can bind the file.  There are a few customizations that you can make.

#### Docker volume mounting

Change the `/output` and `/input` as you see fit just make sure you tell participants to write to the correct output directory and read from the correct input directory.

```
mounted_volumes = {output_dir:'/output:rw',
                   input_dir:'/input:ro'}
```

#### Log file

The logging of these Docker containers are done with functions `store_log_file` and `create_log_file` in `run_docker.py`. It is not necessary to return log files, but the log files do assist submitters in debugging their submission.

The log file size can also be restricted.  If you want to remove this, simply add `statinfo.st_size/1000.0 <= 50` or a separate restriction.  The particular restriction is that the log file will not be updated when it is larger than 50K.  The log file size limit is implemented to ensure submitters aren't writing private data into their logs.

#### Docker run parameters

It is important to notice that the `network_disabled=True` so that submitter models cannot upload the private dataset anywhere.  Furthermore a `mem_limit` is set on the model so that concurrent models can be run without causing the instance running these models to run out of memory.

```
container = client.containers.run(docker_image,
                                  detach=True, volumes=volumes,
                                  name=args.submissionid,
                                  network_disabled=True,
                                  mem_limit='10g', stderr=True)
```

#### Output

The default output is `predictions.csv`, but this could easily be multiple outputs.  Just make sure you link up the rest of the workflow correctly.


#### Run docker

This can be any path onto your local file system as a directory or particular file.  It will be mounted into the submitted Docker container.

```
- id: input_dir
  # Replace this with correct datapath
  valueFrom: "/home/thomasyu/input"
```

## Testing

This repository is fully tested.  You will need the credentials for the Synapse user: `workflow-tester` found in LastPass (Sage employees only).  To run the tests, you will need to create a Synapse config file (`.synapseConfig`) within the `/tmp` directory. Run the tests with:

```
pipenv run cwltest --test conformance_tests.yaml --tool cwl-runner
```