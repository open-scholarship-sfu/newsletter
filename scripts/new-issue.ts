// Creates the file for a new newsletter issue from issues/_starter.qmd.
//
//   quarto run scripts/new-issue.ts            this month
//   quarto run scripts/new-issue.ts 2027-01    a given month
//
// The new file is issues/YYYY-MM-month.qmd, with the date set to the first of
// the month and no issue number. If the file already exists, nothing is
// changed.
// It uses the runtime bundled with Quarto, so there's nothing to install.

const MONTHS = ["january", "february", "march", "april", "may", "june", "july",
  "august", "september", "october", "november", "december"];

const arg = Deno.args[0];
const now = new Date();
let year = now.getUTCFullYear();
let month = now.getUTCMonth() + 1;
if (arg) {
  const m = arg.match(/^(\d{4})-(\d{2})$/);
  if (!m || +m[2] < 1 || +m[2] > 12) {
    console.error(`Expected a month like 2027-01, got "${arg}"`);
    Deno.exit(1);
  }
  year = +m[1];
  month = +m[2];
}
const mm = String(month).padStart(2, "0");
const path = `issues/${year}-${mm}-${MONTHS[month - 1]}.qmd`;

function setOutput(key: string, value: string) {
  const out = Deno.env.get("GITHUB_OUTPUT");
  if (out) Deno.writeTextFileSync(out, `${key}=${value}\n`, { append: true });
}
setOutput("path", path);
setOutput("month", `${year}-${mm}`);

try {
  Deno.statSync(path);
  console.log(`${path} already exists; nothing to do.`);
  setOutput("created", "false");
  Deno.exit(0);
} catch {
  // the file doesn't exist yet: carry on
}

let text = Deno.readTextFileSync("issues/_starter.qmd");
// drop the starter's own instructions (comment lines at the top of the front matter)
text = text.replace(/^---\n(?:#.*\n)+/, "---\n");
text = text.replace(/^date:.*$/m, `date: ${year}-${mm}-01  # change to the send date`);
// leave out the starter's issue number
text = text.replace(/^issue:.*\n/m, "");

Deno.writeTextFileSync(path, text);
console.log(`Created ${path}.`);
setOutput("created", "true");
