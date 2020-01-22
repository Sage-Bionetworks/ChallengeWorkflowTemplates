# ChallengeWorkflowTemplates

These are the collection of challenge CWL workflows and tools that can be linked with the [Synapse Workflow Orchestrator](https://github.com/Sage-Bionetworks/SynapseWorkflowOrchestrator).  These are three different challenge workflows:

1. **Scoring Harness**: Participants submit prediction files and these files are validated and scored.
1. **Docker Agent**: Participants submit a docker container with their model, which then runs against internal data and a prediction file is generate.  This prediction file is then validated and scored.
1. **Ladder Scoring Harness**: Participants submit prediction files but these files are compared against leading submissions.

This readme will guide you to learn how to use these challenge templates.  Here are some example challenges that currently use these templates: 

* [CTD^2 Panacea Challenge](https://github.com/Sage-Bionetworks/CTDD-Panacea-Challenge)
* [RA2-DREAM-challenge](https://github.com/Sage-Bionetworks/RA2-dream-workflows)
* [CTD^2 BeatAML Challenge](https://github.com/Sage-Bionetworks/CTD2-BeatAML-Challenge)
* [Allen Institute Cell Lineage Reconstruction DREAM Challenge](https://github.com/Sage-Bionetworks/Allen-DREAM-Challenge)
* [Metadata Automation DREAM Challenge](https://github.com/Sage-Bionetworks/metadata-automation-challenge/tree/master/workflow)
* [EHR DREAM Challenge](https://github.com/Sage-Bionetworks/EHR-challenge)

You will notice that these examples linked above do not contain all the tools you see in this repository, but instead the `run` steps link out to specific tagged versions of these tools.  This specific step below is using `v2.1` of the `get_submission.cwl` tool.

```
download_submission:
  run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v2.1/get_submission.cwl
...
```

## Scoring Harness

* Workflow: `scoring_harness_workflow.cwl`
* Recommended tools to edit: `validate.cwl`, `score.cwl`

### Validation: validate.cwl

This tool can be changed to validate whatever format participants submit their predictions.  It must write results to a JSON file that has keys `prediction_file_status` and `invalid_reasons`.

* `prediction_file_status`: status of the prediction file - `VALIDATED`, `INVALID`
* `invalid_reasons`: `\n` joined set of strings that define whatever is wrong with the prediction file (empty string is nothing wrong)

### Scoring: score.cwl

This tool scores the prediction file against a truth file. It must write results to a JSON file that has keys `prediction_file_status` and `user_defined_score`.

* `prediction_file_status`: status of the prediction file - `SCORED`
* `user_defined_score`: This is an annotation that you want to add to the submission, so it should describe what the score is such as `auc`, `aupr`, `f1`, and etc.

### Workflow Steps: scoring_harness_workflow.cwl

**Annotation**
```
annotate_submission:
  run: https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates/tree/v2.1/annotate_submission.cwl
  in:
    - id: submissionid
      source: "#submissionId"
    - id: annotation_values
      source: "#validate_docker/results"
    - id: to_public
      default: true
    - id: force_change_annotation_acl
      default: true
    - id: synapse_config
      source: "#synapseConfig"
  out: []
```
The values `to_public` and `force_change_annotation_acl` can be `true` or `false`.  `to_public` controls the ACL of each annotation key passed in during the annotation step, while `force_change_annotation_acl` allows for the same annotation key to change ACLs.  For instance, if the original annotations had annotation `A` that was private, and annotation `A` was passed in again as a public annotation, this would fail the pipeline.  However, passing in `force_change_annotation_acl` as `true` would allow for this change.

**Download Synapse File**

You can pass in a synapse id here to download the file you need for the workflow.  An example would be downloading the truth file required for challenges.
```
  download_goldstandard:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/synapse-client-cwl-tools/v0.1/synapse-get-tool.cwl
    in:
      - id: synapseid
        #This is a dummy syn id, replace when you use your own workflow
        valueFrom: "syn1234"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath
```

**Messages**

`{notificiation,validate,score}_email.cwl` are general templates for submission emails.  You may edit the body of the email to change the subject title and message sent.

If you would not like to email participants, simply comment these steps out.  These workflow steps are required for challenges because participants should only be receiving pertinent information back from the scoring harness.  If the scoring code breaks, it is the responsibility of the administrator to receive notifications and fix the code.


## Docker Agent
* Workflow: docker_agent_workflow.cwl
* Recommended tools to edit: `run_docker.cwl/run_docker.py`, `validate.cwl`, `score.cwl`

### Running Docker Submission: run_docker.cwl/run_docker.py

Please note that the this run docker step has access to your local file system, but the output file must be written to the current working directory of the CWL environment such that CWL can bind the file.  There are a few customizations that you can make.

**Docker volume mounting**

Change the `/output` and `/input` as you see fit just make sure you tell participants to write to the correct output directory and read from the correct input directory.

```
mounted_volumes = {output_dir:'/output:rw',
                   input_dir:'/input:ro'}
```

**Log file**

The logging of these Docker containers are done with functions `store_log_file` and `create_log_file` in `run_docker.py`. It is not necessary to return log files, but the log files do assist submitters in debugging their submission.

The log file size can also be restricted.  If you want to remove this, simply add `statinfo.st_size/1000.0 <= 50` or a separate restriction.  The particular restriction is that the log file will not be updated when it is larger than 50K.  The log file size limit is implemented to ensure submitters aren't writing private data into their logs.

**Docker run parameters**

It is important to notice that the `network_disabled=True` so that submitter models cannot upload the private dataset anywhere.  Furthermore a `mem_limit` is set on the model so that concurrent models can be run without causing the instance running these models to run out of memory.

```
container = client.containers.run(docker_image,
                                  # 'bash /app/train.sh',
                                  detach=True, volumes=volumes,
                                  name=args.submissionid,
                                  network_disabled=True,
                                  mem_limit='10g', stderr=True)
```

**Output**

The default output is `predictions.csv`, but this could easily be multiple outputs.  Just make sure you link up the rest of the workflow correctly.

## Workflow Steps:

**Run docker**

This can be any path onto your local file system as a directory or particular file.  It will be mounted into the submitted Docker container.

```
- id: input_dir
  # Replace this with correct datapath
  valueFrom: "/home/thomasyu/input"
```

**Download goldstandard**

See instructions above for the `Scoring Harness` setup.

**Annotations**

See instructions above for the `Scoring Harness` setup.

**Validation / Scoring / Messaging**

See instructions above for the `Scoring Harness` setup.
