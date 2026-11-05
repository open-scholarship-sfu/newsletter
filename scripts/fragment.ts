// Runs after every render (it uses the Deno runtime bundled with Quarto, so
// nothing needs installing). It does two things to each rendered email:
//
// 1. When `fragment: true`, Quarto still wraps the output in
//    <html><head></head><body>...</body></html>; this removes that wrapper so
//    the file can be pasted straight into a mailing platform's editor.
//
// 2. It writes every non-ASCII character (curly quotes, dashes, accents,
//    emoji) as an HTML code, such as &#8217; for ’. A pasted fragment has no
//    <meta charset>, so mailing platforms and browsers may read it with the
//    wrong encoding and show "isnâ€™t" instead of "isn’t". The codes are plain
//    ASCII, so they display correctly whatever encoding is assumed.
const files = (Deno.env.get("QUARTO_PROJECT_OUTPUT_FILES") ?? "")
  .split("\n")
  .filter((f) => f.endsWith(".html"));

function asciiOnly(s: string): string {
  let out = "";
  for (const ch of s) {
    const code = ch.codePointAt(0)!;
    out += code > 127 ? `&#${code};` : ch;
  }
  return out;
}

for (const f of files) {
  let s = Deno.readTextFileSync(f);
  const m = s.match(/^\s*<html><head>\s*<\/head><body>([\s\S]*)<\/body><\/html>\s*$/);
  if (m) s = m[1].trim() + "\n";
  Deno.writeTextFileSync(f, asciiOnly(s));
}
