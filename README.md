# Challenge Workflow CWL Tools

A collection of CWL tools for Synapse challenge infrastructure workflows, designed to work with the [Synapse Workflow Orchestrator](https://github.com/Sage-Bionetworks/SynapseWorkflowOrchestrator).
## Authors

- [Thomas Yu](https://github.com/thomasyu888)
- [Verena Chung](https://github.com/vpchung)
- [Andrew Lamb](https://github.com/andrewelamb)

## Workflow Types

There are three supported challenge workflows:

| Type | Description | Reference |
|------|-------------|-----------|
| **Data to Model** | Participants submit prediction files that are validated and scored. | [data-to-model-challenge-workflow](https://github.com/Sage-Bionetworks-Challenges/data-to-model-challenge-workflow) |
| **Model to Data** | Participants submit a Docker container; the model runs against internal data to produce a prediction file, which is then validated and scored. | [model-to-data-challenge-workflow](https://github.com/Sage-Bionetworks-Challenges/model-to-data-challenge-workflow) |
| **Ladder Classic** | Participants submit prediction files that are scored against the current leading submission. | — |

### Example Challenges

The following challenges use these templates. Note that their `run` steps reference specific tagged versions of the tools rather than the full tool set in this repository.

- [CTD^2 Panacea Challenge](https://github.com/Sage-Bionetworks/CTDD-Panacea-Challenge)
- [RA2 DREAM Challenge](https://github.com/Sage-Bionetworks/RA2-dream-workflows)
- [CTD^2 BeatAML Challenge](https://github.com/Sage-Bionetworks/CTD2-BeatAML-Challenge)
- [Allen Institute Cell Lineage Reconstruction DREAM Challenge](https://github.com/Sage-Bionetworks/Allen-DREAM-Challenge)
- [Metadata Automation DREAM Challenge](https://github.com/Sage-Bionetworks/metadata-automation-challenge/tree/master/workflow)
- [EHR DREAM Challenge](https://github.com/Sage-Bionetworks/EHR-challenge)

For example, the step below references `v3.0` of `get_submission.cwl`:

```yaml
download_submission:
  run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.0/cwl/get_submission.cwl
  ...
```

---

## CWL Tools

### Annotation

`annotate_submission.cwl` writes key-value annotations back to a Synapse submission.

```yaml
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

**Parameters:**

- `to_public` — Controls the ACL of each annotation key. Set to `true` to make annotations publicly visible.
- `force` — Allows an existing annotation key to change its ACL. Without this, attempting to change the visibility of an existing annotation will fail.

### Email Notifications

`notification_email.cwl`, `validate_email.cwl`, and `score_email.cwl` are templates for sending submission status emails. Edit the subject and body in each file to customize what participants receive.

To disable emails for a workflow step, comment out the relevant step. Keeping email steps active is recommended so that participants receive feedback and administrators are alerted if the scoring harness fails.

### Running Docker Submissions

`run_docker.cwl` and `run_docker.py` execute a participant's submitted Docker container. The container reads from `/input` (read-only) and writes to `/output` (read-write). Any output must be written to `/output` so CWL can bind it back.

The only values you need to customize in the workflow step:

| Parameter | What to set | Default |
|-----------|-------------|---------|
| `input_dir` | Absolute path to the input data on the host | _(required)_ |
| `container_time_limit` | Execution timeout in seconds | `7200` (2 h) |
| `container_memory_limit` | Memory cap (e.g. `4g`) | `2g` |
| `container_memory_swap_limit` | Swap limit — set equal to `container_memory_limit` to disable swap | `2g` |

```yaml
- id: input_dir
  valueFrom: "/data/input"   # ← replace with your data path
- id: container_time_limit
  default: 7200
- id: container_memory_limit
  default: "2g"
```

The expected output file is `predictions.csv`. If your challenge uses a different filename, update `expected_output` in `run_docker.py` and the downstream workflow steps accordingly.

> **Note:** Containers run with `network_disabled=True` to prevent models from exfiltrating private data. Container logs are capped at 50 KB to prevent submitters from writing sensitive data into them.

---

## Testing

Tests require credentials for the Synapse user `workflow-tester` (available in LastPass for Sage employees). Before running tests, create a `.synapseConfig` file in `/tmp`.

```bash
pipenv run cwltest --test conformance_tests.yaml --tool cwl-runner
```

---

## Resources

| Resource | Description |
|----------|-------------|
| [CWL v1.0 Specification](https://www.commonwl.org/v1.0/) | Full language reference for CWL v1.0 (the only version supported by the Synapse Workflow Orchestrator) |
| [CWL User Guide](https://www.commonwl.org/user_guide/) | Beginner-friendly introduction to writing CWL tools and workflows |
| [Synapse Workflow Orchestrator](https://github.com/Sage-Bionetworks/SynapseWorkflowOrchestrator) | The orchestrator that runs these workflows against Synapse submissions |
| [cwl-tool-synapseclient](https://github.com/Sage-Bionetworks-Workflows/cwl-tool-synapseclient) | Additional CWL tools for interacting with Synapse |
| [data-to-model-challenge-workflow](https://github.com/Sage-Bionetworks-Challenges/data-to-model-challenge-workflow) | Reference workflow for Data-to-Model challenges |
| [model-to-data-challenge-workflow](https://github.com/Sage-Bionetworks-Challenges/model-to-data-challenge-workflow) | Reference workflow for Model-to-Data challenges |