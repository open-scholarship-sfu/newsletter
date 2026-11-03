# Open Scholarship newsletter template (Quarto)

Write each issue in Markdown, run `quarto render`, and upload the HTML file to
your mailing platform. The output is a 600px, table-based email with every
style inlined, so it holds up in Outlook, Gmail and Apple Mail and stacks to a
single column on phones. Nothing needs installing beyond Quarto 1.4+.

## Folder layout

```
_quarto.yml                 newsletter-wide settings (name, colours, footer)
_extensions/osnews/         the template: shell HTML + Lua filter
issues/_starter.qmd         blank issue to copy (files starting with _ aren't rendered)
issues/2026-11-november.qmd sample issue using every component (placeholder content)
issues/images/              images for issues
_output/issues/*.html       rendered emails to upload
```

## Making a new issue

1. Copy `issues/_starter.qmd` to `issues/2026-12-december.qmd` and fill it in.
2. Preview while writing: `quarto preview issues/2026-12-december.qmd`.
3. Upload the issue's images to Campaigner's image library (or any public web
   host), then set `image-base-url` in `_quarto.yml` to that folder's URL.
   Relative paths such as `images/photo.jpg` become
   `<image-base-url>/images/photo.jpg`. Full `https://` image URLs are left as is.
4. `quarto render`, then upload `_output/issues/2026-12-december.html`.
5. Send yourself a test before the real send.


## Pasting into Campaigner

With `fragment: true` in `_quarto.yml` (the default), the rendered file is
just the newsletter card, with no page background or outer padding. It fills
the width of Campaigner's HTML block up to 600px. Open the rendered `.html`
file in a text editor, copy everything, and paste it into the block.

Set `fragment: false` to get a complete standalone HTML page instead, with
its own background and a fixed 600px card. Use that if you import a whole
HTML email rather than pasting into a block.

`scripts/fragment.ts` runs automatically after each render to tidy the
fragment. It uses the runtime bundled with Quarto, so there's nothing to
install.

## Writing an issue

Front matter: `title`, `subtitle`, `issue`, `date` (shown as "November 2026"),
and `preheader` (the grey preview text in inboxes).

Text before the first `##` heading is the intro note. Each `## Heading` starts
a new section; add `{.tinted}` for a shaded one. When there are two or more
sections, an "In this issue" box with jump links appears after the intro (turn
off with `in-this-issue: false`).

Regular Markdown works everywhere: `###` and `####` headings, lists, links,
bold, quotes, images, tables and `---` dividers.

### Components

**Buttons.** A paragraph containing only button links becomes a button row.

```markdown
[Register](https://...){.button}
[Learn more](https://...){.button .secondary}
```

**Featured story** with a large image (520px wide; export at 1040px for sharp
retina display). `link` makes the image clickable.

```markdown
::: {.feature image="images/story.jpg" alt="..." link="https://..."}
### Title
Text.
:::
```

**Event** with a date tile. Use `YYYY-MM-DD` for `date` and the weekday is
filled in for you. `time` and `place` are optional.

```markdown
::: {.event date="2026-11-18" time="10:00 to 11:30 a.m." place="Online"}
### Title
Text.
:::
```

**Spotlight** with a round photo (square image, at least 184px).

```markdown
::: {.spotlight image="images/person.jpg" alt="Portrait of ..."}
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

**Two columns** that stack on phones. Each column may have an image
(export at 496px wide).

```markdown
::: two-col
::: {.col image="images/a.jpg" alt="..." link="https://..."}
#### Item one
Text.
:::
::: {.col image="images/b.jpg" alt="..."}
#### Item two
Text.
:::
:::
```

## Customising

All settings live under `newsletter:` in `_quarto.yml` and can be overridden
in an issue's front matter: name, organisation line, optional logo, colours,
font stacks, and the footer (about text, contact, links, land acknowledgement,
text below the card).

For unsubscribe or "view in browser" links, paste your mailing platform's
merge tags into `footer: raw-html:`. Most platforms also add their own
compliance footer automatically; check yours before adding a second one.

## Tips

- Always give images `alt` text: many readers see emails with images off.
- Keep a single issue under ~100 KB of HTML; Gmail clips longer messages.
- Avoid `::: callout-note` and other Quarto callouts; use `::: highlight`.
