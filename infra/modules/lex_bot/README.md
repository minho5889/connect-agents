# Module: lex_bot

Lex V2 bot for Aria + its association with the Connect instance.

## Verified findings that shaped this module

1. **`aws_connect_bot_association` is Lex V1-only** (provider docs state it
   explicitly). A Lex **V2** bot is associated via
   `AWS::Connect::IntegrationAssociation` — the CFN docs include an explicit
   Lex V2 example (`IntegrationType: LEX_BOT`, `IntegrationArn` = the **bot
   alias ARN**) — surfaced in Terraform as the `awscc` integration-association
   resource (skeleton in `main.tf`).
2. **`aws_lexv2models_bot`** args are verified and written in full (+ IAM role).
3. **Locale / version / alias** resource shapes are NOT verified here — they're
   commented skeletons. Complete them against the live schemas using the
   **terraform MCP server** (now configured; tools available after an app
   restart), then enable the association.

## ⚠️ The QinConnectIntent caveat (affects how much can be IaC)

Verified from the Connect Admin Guide: the **Connect AI agents intent toggle
(`AMAZON.QinConnectIntent`) is only supported for bots created inside the
Connect Customer admin website**. For bots created elsewhere (console, CLI,
Terraform), the intent must be enabled via the **Amazon Lex console** instead.

Practical consequence for Aria: even with this module deployed, enabling the
AI-agent intent on the bot is a **documented manual step** (Lex console →
bot → add `AMAZON.QinConnectIntent`), and Nova Sonic speech-to-speech is
configured per-locale in the Connect admin site. Treat this module as the
*infrastructure* for the bot; the agentic intent wiring is config-on-top.
An alternative that maximizes IaC fidelity: create the bot in the Connect
admin site once (gets the toggle), and manage everything *around* it in
Terraform.
