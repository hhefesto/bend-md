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
computed. Mutants (`./mutants.sh`): quote-passes, lt-written-as-is,
each caught. Not yet: that the HTML is cmark-gfm's (checked by
compare.sh), that link targets are inert too.

## This repository

Written for mugen-app (mugen's chat in a browser) as part of its Bend
backend, which replaced a Haskell one: a mention above of `backend/`,
`server/` or `server/test/compare.sh` is that app's. The libraries written
with it: [bend-wire](https://github.com/hhefesto/bend-wire), [bend-route](https://github.com/hhefesto/bend-route), [bend-json](https://github.com/hhefesto/bend-json), [bend-files](https://github.com/hhefesto/bend-files), [bend-sha2](https://github.com/hhefesto/bend-sha2), [bend-radix](https://github.com/hhefesto/bend-radix), [bend-text](https://github.com/hhefesto/bend-text), [bend-time](https://github.com/hhefesto/bend-time), [bend-entropy](https://github.com/hhefesto/bend-entropy), [bend-bcrypt](https://github.com/hhefesto/bend-bcrypt), [bend-bucket](https://github.com/hhefesto/bend-bucket).

**Using it.** Bend imports by path: clone this repository as `bend-md/`
beside your code, with the ones it imports beside it (`bend-text/`),
and import it: `import ../bend-md/Md.bend as X`. In a Nix build, copy the flake's
source (or its `packages.default`) there.

**Checks** (`nix flake check`, with the pinned Bend 2.0.39):
`bend PROOF.bend --verdict` (its laws, rechecked by the BendTT kernel);
`./mutants.sh` (each mistake in `probe/mutants/` caught by the laws);
`bend FILE.bend --check-only` on each module.

**License**: MIT (`LICENSE`).
