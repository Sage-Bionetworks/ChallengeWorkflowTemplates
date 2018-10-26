# ChallengeWorkflowTemplates

These are the two boiler plate challenge workflows that can be linked with the [Synapse workflow hook](https://github.com/Sage-Bionetworks/SynapseWorkflowHook).  There are two different challenge infrastructures:

1. Scoring Harness - Participants submit prediction files and these files are validated and scored.
2. Docker Agent - Participants submit a docker container, which then generates a prediction file.


## Scoring Harness
* Workflow: scoring_harness_workflow.cwl
* Tools: annotate_submission.cwl, download_submission_file.cwl, score.cwl, score_email.cwl, validate.cwl, validate_email.cwl, download_from_synapse.cwl

### Making edits to the scoring harness.

* Validation: validate.cwl

This file can be changed to validate whatever format participants submit their predictions.  It must have `status` and `invalid_reasons` as outputs where `status` is the `prediction_file_status` and `invalid_reasons` is a `\n` joined set of strings that define whatever is wrong with the prediction file. 

* Scoring: score.cwl

This script scores the prediction file against the goldstandard. It must have `results` output which is a json file with the key `prediction_file_status`.

* Annotations: scoring_harness_workflow.cwl

There are a couple inputs that the annotation workflow step takes.  Below is an example of a workflow step

```
  annotate_submission:
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
```
The values `to_public` and `force_change_annotation_acl` can be 'true' or 'false'.  `to_public` controls the ACL of each annotation key passed in during the annotation step, while `force_change_annotation_acl` allows for the same annotation key to change ACLs.  For instance, if the original annotations had annotation A that was private, and annotation A was passed in again as a public annotation, this would fail the pipeline.  However, passing in `force_change_annotation_acl` as 'true' would allow for this change.

* Download goldstandard: scoring_harness_workflow.cwl

You can pass in a synapse id here to download the goldstandard file for a specific challenge.  Example input is
```
  download_goldstandard:
    run: download_from_synapse.cwl
    in:
      - id: synapseid
        #This is a dummy syn id, update syn12345 value to real Synapse id
        valueFrom: "syn12345"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath
```

* Messaging: validate_email.cwl and score_email.cwl

Both of these are general templates for submission emails.  You may edit the body of the email to change the subject title and message sent.

If you would not like to email participants, simply comment these steps out.  These workflow steps are required for challenges because participants should only be receiving pertinent information back from the scoring harness.  If the scoring code breaks, it is the responsibility of the administrator to receive notifications and fix the code.


## Docker Agent
* Workflow: docker_agent_workflow.cwl
* Tools: annotate_submission.cwl, get_submission_docker.cwl, score.cwl, score_email.cwl, validate.cwl, validate_email.cwl, download_from_synapse.cwl, get_docker_config.cwl, notification_email.cwl, validate_docker.cwl, run_docker.cwl, upload_to_synapse.cwl

### Making edits to the docker agent.

* Running Docker Submission:  run_docker.cwl

Please note that the this run docker step has access to your local file system, but the output file must be written to the current working directory of the CWL environment such that CWL can bind the file.  There are a few customizations that you can make.

**Input files**:

This can be any path onto your local file system as a directory or particular file
```
- valueFrom: /path/to/directory/
prefix: -i
```

**Directory path that is mounted into docker run**

Change the `/output` and `/input` as you see fit just make sure you tell participants to write to the correct output directory and read from the correct input directory.
```
mounted_volumes = {output_dir:'/output:rw',
                 input_dir:'/input:ro'}
```

**Log file**

Log files do not need to be returned.  An entire chunk of code can be commented out to not return log files from line 117 to line 145.

The log file size can also be restricted.  If you want to remove this, simply remove `statinfo.st_size/1000.0 <= 50` or you can provide a separate restriction.  The current restriction is that the log file will not be updated when its larger than 50K.
```
if statinfo.st_size > 0 and statinfo.st_size/1000.0 <= 50:
```

**Output**

The default output is `predictions.csv`, but this could easily be multiple outputs.  Just make sure you link up the rest of the workflow correctly.

* Download goldstandard: docker_agent_workflow.cwl

See instructions above for the `Scoring Harness` setup.

* Annotations: docker_agent_workflow.cwl

See instructions above for the `Scoring Harness` setup.

* Validation / Scoring / Messaging 

See instructions above for the `Scoring Harness` setup.



