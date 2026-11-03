# Open Scholarship News

The [Open Scholarship Initiative at SFU](https://www.sfu.ca/research/research-impact/performance-excellence/open-science.html) encourages researchers to share their
work openly: to make it transparent, reproducible and reusable. This
repository applies the same principles to our own newsletter. Every issue is
written in plain text, rendered with open-source tools, and kept here with its
full history, so anyone can see exactly how each issue was made and what was
sent. The template is shared under a CC BY 4.0 licence, so other teams at SFU
and beyond can reuse and adapt it for their own communications.

## How it works

Each issue is written in Markdown and rendered with Quarto into an email
that we paste into Campaigner. The output is a table-based email with every
style inlined, so it holds up in Outlook, Gmail and Apple Mail and stacks to
a single column on phones. Nothing needs installing beyond
[Quarto 1.4 or later](https://quarto.org/docs/get-started/).

Want to help, or share news for an upcoming issue? See
[CONTRIBUTING.md](CONTRIBUTING.md).

## Folder layout

```
_quarto.yml                 newsletter-wide settings (name, colours, footer, image address)
_extensions/osnews/         the template: shell HTML and Lua filter
scripts/fragment.ts         tidies the output after each render (runs automatically)
issues/_starter.qmd         blank issue to copy (files starting with _ aren't rendered)
issues/YYYY-MM-month.qmd    one file per issue
issues/images/              placeholder images used by the starter, and archive copies
_output/issues/*.html       rendered emails, committed as the record of what was sent
.github/                    issue forms and the pull request template
```

## Making a new issue

1. Copy `issues/_starter.qmd` to `issues/2026-12-december.qmd` and fill it
   in.
2. Upload the issue's images to Campaigner's image library (see
   [Images](#images)).
3. Preview while writing:

   ```bash
   quarto preview issues/2026-12-december.qmd
   ```

4. Render **only that issue**:

   ```bash
   quarto render issues/2026-12-december.qmd
   ```

   Don't run `quarto render` on its own: it re-renders every published issue
   with the current template, so they would no longer match what was sent.

5. Open `_output/issues/2026-12-december.html` in a text editor, copy
   everything, and paste it into Campaigner's HTML block.
6. Send yourself a test before the real send.

## Images

Images are hosted in Campaigner's image library, and its address is already
set as `image-base-url` in `_quarto.yml`. To use an image:

1. Upload it to Campaigner exactly as supplied, without editing it.
2. In the issue, write its file name exactly as it appears in Campaigner,
   with nothing in front of it: no folder and no web address.

   ```markdown
   ::: {.feature image="os_newsletter-nov2026-km_workshops.jpg" alt="..."}
   ```

The template adds the Campaigner address when rendering, so both the preview
and the email load the image from Campaigner. If an image doesn't appear,
check that it's uploaded and that the name matches Campaigner's character for
character. Avoid spaces in file names. Full `https://` addresses are left as
written.

## Pasting into Campaigner

With `fragment: true` in `_quarto.yml` (the current setting), the rendered
file is just the newsletter card, with no page background or outer padding.
It fills the width of Campaigner's HTML block, up to 600px.

Set `fragment: false` to get a complete standalone HTML page instead, with
its own background and a fixed 600px card.

## Writing an issue

Front matter: `title`, `subtitle`, `issue`, `date` (written as `YYYY-MM-DD`,
shown as "November 2026"), and `preheader` (the preview text shown in
inboxes).

Text before the first `##` heading is the intro. Each `## Heading` starts a
new section; add `{.tinted}` for a shaded one. When there are two or more
sections, an "In this issue" line with jump links appears after the intro
(turn off with `in-this-issue: false`).

Regular Markdown works everywhere: `###` and `####` headings, lists, links,
bold, quotes, images, tables and `---` dividers.

### Components

**Buttons.** A paragraph containing only button links becomes a row of
buttons.

```markdown
[Register](https://...){.button}
[Learn more](https://...){.button .secondary}
```

**Featured story** with a large image, shown 520px wide. `link` makes the
image clickable.

```markdown
::: {.feature image="story.jpg" alt="..." link="https://..."}
### Title
Text.
:::
```

**Event** with the date in a left column. Write `date` as `YYYY-MM-DD` and
the weekday is filled in for you. `time` and `place` are optional.

```markdown
::: {.event date="2026-11-18" time="10:00 to 11:30 a.m." place="Online"}
### Title
Text.
:::
```

**Spotlight** with a round photo (use a square image).

```markdown
::: {.spotlight image="person.jpg" alt="Portrait of ..."}
#### Name, department
Text.
:::
```

**Highlight box** for deadlines and calls.

```markdown
::: highlight
#### Applications open
Details.
:::
```

**Two columns** that stack on phones. Each column may have an image.

```markdown
::: two-col
::: {.col image="a.jpg" alt="..." link="https://..."}
#### Item one
Text.
:::
::: {.col image="b.jpg" alt="..."}
#### Item two
Text.
:::
:::
```

## Customising

All settings live under `newsletter:` in `_quarto.yml` and can be overridden
in an issue's front matter: name, organisation line, optional logo, colours,
font stacks, and the footer (about text, contact, links, land
acknowledgement, text below the card).

For unsubscribe or "view in browser" links, paste Campaigner's merge tags
into `footer: raw-html:`. Campaigner may also add its own compliance footer;
check before adding a second one.

Changes to `_quarto.yml`, `_extensions/` or `scripts/` affect every issue, so
please propose them first using the "Propose a template change" issue form
(see [CONTRIBUTING.md](CONTRIBUTING.md#changing-the-template)).

## Tips

- Always give images `alt` text: many readers see emails with images off.
- Keep a single issue under about 100 KB of HTML; Gmail clips longer
  messages.
- Avoid `::: callout-note` and other Quarto callouts; use `::: highlight`.

## Licence

Shared under the [CC BY 4.0 licence](LICENSE).
