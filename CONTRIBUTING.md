# Contributing to the Open Scholarship newsletter

Thanks for helping with the newsletter! This repository holds the template
and the source of every issue, written in Markdown and rendered with Quarto
into the HTML we paste into Campaigner.

Most contributions are **writing or editing an issue** in `issues/`, which
only needs Markdown. The template itself (`_quarto.yml`, `_extensions/` and
`scripts/`) is working and shared by every issue, so please don't change it
without discussing it first (see [Changing the template](#changing-the-template)).

## Before you start

1. Install [Quarto 1.4 or later](https://quarto.org/docs/get-started/).
2. Clone the repository.
3. Create a branch for your work, named after the issue:

   ```bash
   git switch -c issue/2026-12-december
   ```

Please don't commit directly to `main`.

## The rendering rule

**Render only the issue you're working on.** Never run `quarto render` on
its own.

```bash
quarto render issues/2026-12-december.qmd
```

The rendered emails in `_output/` are committed, and they are the record of
what was sent. Running `quarto render` without a file name re-renders every
issue, including ones already published, so they would no longer match what
readers received.

If you run a full render by accident, undo it before committing:

```bash
git restore _output/
quarto render issues/2026-12-december.qmd
```

## Writing an issue

### Files and names

- Copy `issues/_starter.qmd` to `issues/YYYY-MM-month.qmd`, for example
  `issues/2026-12-december.qmd`.
- Files whose names start with `_` are not rendered. Use that for drafts or
  examples you want to keep in the repository.

### Front matter

Fill in every field from the starter:

| Field | What it's for |
|---|---|
| `title` | The headline shown under the masthead |
| `subtitle` | One sentence on what's inside |
| `issue` | Issue number |
| `date` | Publication date as `YYYY-MM-DD`; shown as "Month Year" |
| `preheader` | The preview text shown in inboxes, around 90 characters, describing this issue |

### Content

- Text before the first `##` heading is the intro. Each `##` heading starts
  a section and appears in the "In this issue" line, so keep section
  headings short.
- Use the components described in the README (`::: feature`, `::: event`,
  `::: highlight`, `::: two-col`, `::: spotlight`, and `{.button}` links).
- Write event dates as `YYYY-MM-DD` so the weekday is filled in correctly,
  and list events in date order.
- Write link text that makes sense on its own ("Register for the workshop",
  not "click here").
- Copy text from the source document faithfully. If you change wording,
  facts, dates or names, say so in your pull request so the author can
  check.

### Images

Images are hosted in Campaigner's image library. Its address is already set
as `image-base-url` in `_quarto.yml`; don't change it.

1. **Upload each image to Campaigner exactly as supplied.** Don't crop,
   resize, recompress or edit it. If an image needs changing, ask whoever
   provided it.
2. **In the issue, write the image's file name exactly as it appears in
   Campaigner**, with the same spelling, capitals and extension, and nothing
   in front of it: no folder and no web address.

   ```markdown
   ::: {.feature image="os_newsletter-nov2026-km_workshops.jpg" alt="..."}
   ```

   The template adds the Campaigner address when rendering, so the preview
   and the email both load the image from Campaigner. If an image doesn't
   appear in the preview, check that it's uploaded and that the name matches
   Campaigner's character for character. Avoid spaces in file names.

3. **Give every image `alt` text.** Many readers see emails with images
   turned off. For posters or banners that contain text, include the key
   information from the image (event name, date, time, place).

The email doesn't need copies of the images in this repository. If you want
to keep an archive copy, put it in `issues/images/YYYY-MM/` under the same
file name as in Campaigner.

### Checking your issue

1. Preview while you write:

   ```bash
   quarto preview issues/2026-12-december.qmd
   ```

2. Render the issue (see [The rendering rule](#the-rendering-rule)) and read
   the output for warnings or errors.
3. Check that every image appears, and click every link.
4. Open `_output/issues/2026-12-december.html` in a text editor, copy
   everything, paste it into Campaigner's HTML block, and send yourself a
   test. Check it on a computer and on a phone.

## Committing

- **Commit the issue and its rendered output together.** The HTML in
  `_output/` should always match the `.qmd` file it came from.
- **Never edit files in `_output/` by hand.** Fix the `.qmd` file and render
  again.
- **Don't change published issues.** Once an issue has been sent, leave both
  its `.qmd` file and its output as they are, even to fix a typo, so the
  repository keeps an accurate record of what was sent.
- **Check `git status` before committing.** Only your issue's files should
  be listed. If another issue's output appears, restore it with
  `git restore _output/issues/<file>.html`.
- **Merge conflicts in `_output/`:** don't fix them line by line. Resolve the
  conflict in the `.qmd` file, render it again and commit the fresh output.

## Changing the template

`_quarto.yml`, `_extensions/` and `scripts/` control how every issue looks
and renders. Please **open a GitHub issue before changing them**, using the "Propose a
template change" form, describing
what you'd like to change and why.

If a change is agreed:

- Make it in its own branch and pull request, separate from any newsletter
  issue.
- Test it by rendering the issue you're working on, pasting it into
  Campaigner and sending a test to a computer and a phone.
- Don't commit re-rendered output of published issues (see
  [Committing](#committing)).
- Update the README if the change affects how issues are written.

## Pull requests

Keep each pull request to one newsletter issue or one template change, and
fill in the pull request template. At least one other person should review
and approve before merging.

## Don't commit

- the `.quarto/` folder (already in `.gitignore`)
- personal information about subscribers, or exported mailing lists
- anything that isn't meant to be public: this repository is public

## Licence

This repository is shared under the
[CC BY 4.0 licence](LICENSE). By contributing, you agree that your
contribution is shared under the same licence. Only contribute text and
images you have permission to share.

## Questions and problems

- **Something isn't working?** Open a GitHub issue using the "Report a
  problem" form.
- **Ideas for changing the template?** Use the "Propose a template change"
  form.
- **General questions, or news to feature in the newsletter?** Email
  [open_scholarship@sfu.ca](mailto:open_scholarship@sfu.ca).
