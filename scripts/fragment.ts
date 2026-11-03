// Runs after every render (it uses the Deno runtime bundled with Quarto, so
// nothing needs installing). When `fragment: true`, Quarto still wraps the
// output in <html><head></head><body>...</body></html>; this removes that
// wrapper so the file can be pasted straight into a mailing platform's HTML
// block. Standalone (fragment: false) files are left untouched.
const files = (Deno.env.get("QUARTO_PROJECT_OUTPUT_FILES") ?? "")
  .split("\n")
  .filter((f) => f.endsWith(".html"));

for (const f of files) {
  const s = Deno.readTextFileSync(f);
  const m = s.match(/^\s*<html><head>\s*<\/head><body>([\s\S]*)<\/body><\/html>\s*$/);
  if (m) Deno.writeTextFileSync(f, m[1].trim() + "\n");
}
