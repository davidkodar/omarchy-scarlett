# Marketplace submission preparation

Checked 2026-09-08 against the official
[publishing guide](https://plugins.omarchy.org/publish.html) and
[CLI submission instructions](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).

The marketplace requires a public GitHub repository with a root manifest,
README, license, dependency documentation and safe install/removal instructions.
Preview images are optional. Submissions are reviewed against a specific commit.
The repository is public. [Submission #5777](https://github.com/omacom/omarchy-plugin-marketplace/issues/5777)
was approved and published on September 10, 2026, at commit `7d97dca`.
The local 0.1.1 update is prepared for separate marketplace review.

Prepared 0.1.1 listing:

- Name: Scarlett for Omarchy
- Category: Hardware
- Tags: bar, media, quickshell
- Scope: native quick controls and startup preference for Scarlett Solo (3rd Gen.) USB 1235:8211.
- Setup: manual setup required after the plugin manager clones the repository;
  run scripts/install.sh to check dependencies, compile and enable. No downloaded
  executable or privileged background service is used.

Before submission, check the marketplace for the permanent ID
`davidkodar.scarlett`, validate the final manifest with `omarchy plugin validate`,
finish the qualification checklist, and review the official form at that time.
Show the owner the completed submission and obtain approval before sending the
marketplace issue. Future-model support belongs
in the roadmap, not in the initial listing's compatibility claim.


## Prepared presentation update

Version 0.1.1 explains the bar-panel use case, identifies the supported generation,
uses actual interface screenshots without the read-only test caption, shows an
exact terminal setup command when the helper cannot start, and adds 48V restart
help. The helper and hardware-control behavior are unchanged.

On September 19 the live catalog still offered the standard add command with
`--enable`, despite the manual build requirement disclosed in the original
submission. The update request should explicitly ask maintainers to mark the
listing as requiring manual setup and point users to the README.

The marketplace counts install-command copies, not successful installations.
At inspection the public counters showed 59 views and 0 copies; this does not
establish the number of users or explain why visitors did not copy the command.
