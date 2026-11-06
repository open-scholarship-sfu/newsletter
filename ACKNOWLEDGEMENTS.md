# Acknowledgements

This newsletter infrastructure is made with open-source tools and builds on ideas shared
openly by others. We're grateful to everyone below.

## Built with

- **[Quarto](https://quarto.org)**, by Posit Software, PBC (MIT License),
  which renders each issue from Markdown. Its bundled runtime also runs
  this repository's helper scripts.
- **[Pandoc](https://pandoc.org)**, by John MacFarlane and contributors
  (GPL), the document converter underneath Quarto. The newsletter's design
  is a Pandoc Lua filter.
- **[quarto-actions](https://github.com/quarto-dev/quarto-actions)**, by
  the Quarto team, and **[GitHub Actions](https://github.com/actions)**,
  which create each month's issue automatically.
- **[Quarto devcontainer feature](https://github.com/rocker-org/devcontainer-features)**,
  by the Rocker Project, which sets up Quarto in GitHub Codespaces.

## Related projects

These projects take similar approaches to writing email in Markdown. We
didn't use their code, but they show how widely the idea is shared, and
they're worth exploring:

- **[mdtoemail](https://github.com/maxedapps/mdtoemail)**: converts
  Markdown into standalone, email-friendly HTML with inline styles and a
  table layout.
- **[emailmd](https://github.com/anypost/emailmd)**: renders Markdown into
  email-safe HTML.
- **[Using Markdown to create responsive HTML emails](https://pbpython.com/markdown-email.html)**,
  by Chris Moffitt, Practical Business Python (2020): an early write-up of a
  Markdown-to-newsletter pipeline with inlined CSS.

## Our community

Thank you to everyone at SFU who shares news, events and stories for the
newsletter, reviews issues before they're sent, and reports problems. Every
contribution is recorded in this repository's history and pull requests.

Something missing from this list? Open an issue or a pull request, or
email [open_scholarship@sfu.ca](mailto:open_scholarship@sfu.ca).
