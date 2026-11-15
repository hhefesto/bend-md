# md: GitHub's markdown (cmark-gfm)

**What it means.** A text means the tree CommonMark's spec gives it, with
GitHub's tables, strikethrough, autolinks (www., http(s)://, ftp://, bare
e-mail addresses) and task lists: blocks (`md.B`: paragraphs, headings, code,
quotes, lists and items, rules, tables, HTML blocks) of inlines (`md.I`:
text, code, breaks, emphasis, strong, strikethrough, links). `md.parse` reads
the tree; `md.html` writes it as cmark's HTML renderer does (text escaped,
link targets %-encoded as houdini does, a tight list's paragraphs bare).

Raw HTML is not passed through: an HTML block is written as a code block of
its text, inline HTML as text (what mugen-web's Render.hs does to
cmark-gfm's tree), so nothing in a text becomes markup it did not mean.

**The machine.** Blocks are read a line at a time into a step (`md.BS`)
that holds a container's lines still to read; inlines a character at a time
into tokens (`md.lex`), then CommonMark's process_emphasis on a stack
(`md.emph`), then GitHub's e-mail links (`md.mails`). Both readers are
total: fuel bounds their steps.

**Checked**, not proved: the page's HTML against the Haskell backend's
(cmark-gfm) on the test chat, by `server/test/compare.sh`: every message of
19 pages of 200 items and the others it asks for, the same bytes. Not
covered: reference links and footnotes, the full HTML5 entity table (44
named entities), a few lazy-continuation corners.

**Laws** (`PROPOSED.bend`, proved in `PROOF.bend`, `--verdict` too):
`esc_inert`, escaped text is inert: whatever a message holds, what `md.esc`
writes of it has no `<`, `>` or `"` of its own (as inert as what follows
it), so text shown as text never becomes markup. Its proof takes each
character's four tests (`&`, `<`, `>`, `"`) as they come out, the 16 cases
computed. Mutants (`../mutants.sh md`): quote-passes, lt-written-as-is,
each caught. Not yet: that the HTML is cmark-gfm's (checked by
compare.sh), that link targets are inert too.
