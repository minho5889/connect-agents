# Module: contact_flow

Deploys an Amazon Connect contact flow from a **vendored, templated JSON
artifact** — the pattern used by AWS's own IaC frameworks (e.g.
[amazon-connect-gitlab-cicd-terraform](https://github.com/aws-samples/amazon-connect-gitlab-cicd-terraform)'s
`templates/ + scripts/replacer` pipeline).

## Why this pattern (read before editing flow JSON)

Contact-flow JSON is a proprietary dialect ([Flow
language](https://docs.aws.amazon.com/connect/latest/devguide/flow-language.html):
`Actions[]`, GUID `Identifiers`, `Transitions/Conditions`, ≤250 actions) and
**hand-authoring it is the #1 source of bugs** — block parameter shapes get
hallucinated/mistyped, and queue/Lex/Lambda ARNs baked into the content break
across environments. So:

> **Never hand-author flow JSON. Author → Export → Template → Deploy.**

1. **Author** the flow in the Connect console flow designer (drag-and-drop).
2. **Export** the known-good JSON: `scripts/export_flow.sh <instance-id>
   <flow-id> <name>` (uses `DescribeContactFlow`, exactly what [AWS
   recommends](https://docs.aws.amazon.com/connect/latest/devguide/flow-language-example.html)
   for learning block identifiers).
3. **Template**: replace env-specific ARNs in the export with
   `${placeholder}` vars → `templates/<name>.json.tftpl`.
4. **Deploy** via this module (`templatefile()` → `aws_connect_contact_flow`).

When changing a flow: change it in the console, re-export, re-diff. The git
diff of the template is your review surface.

## Templates

- `templates/sample_welcome.json.tftpl` — the verified example flow from the
  AWS Flow-language docs (play prompt → disconnect), with a
  `${welcome_message}` placeholder. It proves the deploy pipeline end-to-end.
- `templates/aria_inbound.json.tftpl` — *not vendored yet*: author Aria's
  agentic flow in the console per `docs/02-architecture-reference.md` §9
  (Set voice → Get customer input → Check contact attributes routing), then
  export it here with placeholders for the Lex bot alias ARN and advisor
  queue ARN.

## Usage

```hcl
module "welcome_flow" {
  source = "../../modules/contact_flow"

  instance_id   = module.connect_foundation.instance_id
  name          = "sample-welcome"
  template_path = "${path.root}/../../modules/contact_flow/templates/sample_welcome.json.tftpl"
  template_vars = {
    welcome_message = "Thanks for calling the sample flow!"
  }
}
```

Validate flows after deploy with Connect's native testing & simulation — the
three Aria cases live in `tests/connect_simulation_cases.py`.
