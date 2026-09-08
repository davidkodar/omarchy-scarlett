# Marketplace submission preparation

Checked 2026-09-08 against the official
[publishing guide](https://plugins.omarchy.org/publish.html) and
[CLI submission instructions](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).

The marketplace requires a public GitHub repository with a root manifest,
README, license, dependency documentation and safe install/removal instructions.
Preview images are optional. Submissions are reviewed against a specific commit.
The repository is currently private; no submission has been made.

Suggested listing:

- Name: Scarlett for Omarchy
- Category: Hardware
- Tags: bar, media, quickshell
- Scope: native quick controls and startup preference for Solo USB 1235:8211.
- Setup: manual setup required after the plugin manager clones the repository;
  run scripts/install.sh to check dependencies, compile and enable. No downloaded
  executable or privileged background service is used.

Before submission, check the marketplace for the permanent ID
`davidkodar.scarlett`, validate the final manifest with `omarchy plugin validate`,
finish the qualification checklist, and review the official form at that time.
Show the owner the completed submission and obtain approval before making the
repository public or sending the marketplace issue. Future-model support belongs
in the roadmap, not in the initial listing's compatibility claim.
