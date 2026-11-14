import Base
import ../text/Text.bend as X

# Md: GitHub's markdown (CommonMark with tables, strikethrough, autolinks
# and task lists) read into a tree of blocks and inlines, and the tree
# written as HTML as cmark-gfm writes it (cmark-gfm's job in the Haskell
# backend).
#
# What it means: a text means the tree CommonMark's spec gives it, and the
# HTML means the same tree; `md.html` writes each node as cmark's HTML
# renderer does (text escaped: `&` `<` `>` `"`; links' targets
# %-encoded). Raw HTML in the text is not passed through: Render.hs shows it
# as text (an HTML block as a code block), and so does this.
#
# Every def is prefixed `md.` (a program's defs share one namespace).

# Inlines
type md.I is Data:
  md.IText{s: String}
  md.ICode{s: String}
  md.ISoft{}
  md.IHard{}
  md.IEm{kids: List<&2, md.I>}
  md.IStrong{kids: List<&2, md.I>}
  md.IDel{kids: List<&2, md.I>}
  md.ILink{url: String, title: String, kids: List<&2, md.I>}
  md.IRaw{html: String}

# Blocks. A list's items are md.Item blocks; md.Gap is a blank line between
# blocks (it shows nothing); a list is tight when no blank
# line parts its items or the blocks in them.
type md.Al is Data:
  md.ANone{}
  md.ALeft{}
  md.ACenter{}
  md.ARight{}

type md.B is Data:
  md.Para{kids: List<&2, md.I>}
  md.Head{level: Nat, kids: List<&2, md.I>}
  md.Code{info: String, body: String}
  md.Quote{kids: List<&2, md.B>}
  md.List{ordered: Bool, start: Nat, spaced: Bool, items: List<&2, md.B>}
  md.Item{task: Nat, kids: List<&2, md.B>}
  md.Gap{}
  md.Rule{}
  md.Table{al: List<&2, md.Al>, head: List<&2, List<&2, md.I>>, rows: List<&2, List<&2, List<&2, md.I>>>}
  md.Html{html: String}
  md.Raw{html: String}

# Characters
# ----------

def md.if(-A: Data, b: Bool, t: Unit -> A, e: Unit -> A) -> A:
  match b:
    case True{}:
      t(Unit{})
    case False{}:
      e(Unit{})

def md.ascii.punct(+c: U32) -> Bool:
  (U32.is_ge(c, 33) && U32.is_le(c, 47)) || (U32.is_ge(c, 58) && U32.is_le(c, 64)) || (U32.is_ge(c, 91) && U32.is_le(c, 96)) || (U32.is_ge(c, 123) && U32.is_le(c, 126))

# Unicode punctuation (cmark's: ASCII's, and the general punctuation and
# symbol blocks a chat meets)
def md.punct(+c: U32) -> Bool:
  md.ascii.punct(c) || (U32.is_ge(c, 161) && (U32.is_eq(c, 161) || U32.is_eq(c, 167) || U32.is_eq(c, 171) || U32.is_eq(c, 182) || U32.is_eq(c, 183)
    || U32.is_eq(c, 187) || U32.is_eq(c, 191) || (U32.is_ge(c, 8208) && U32.is_le(c, 8231)) || (U32.is_ge(c, 8240) && U32.is_le(c, 8286))
    || (U32.is_ge(c, 12289) && U32.is_le(c, 12291)) || (U32.is_ge(c, 12296) && U32.is_le(c, 12305))))

def md.white(+c: U32) -> Bool:
  X.tx.space(c)

# Escaping (cmark's houdini)
# -------------------------

def md.esc.c(+c: U32) -> String:
  md.if(String, U32.is_eq(c, 38), u => "&amp;", u => md.if(String, U32.is_eq(c, 60), u => "&lt;", u => md.if(String, U32.is_eq(c, 62), u => "&gt;",
    u => md.if(String, U32.is_eq(c, 34), u => "&quot;", u => SCon{Chr{c}, ""}))))

def md.esc.at(plain: Bool, +c: U32, rest: String) -> String:
  match plain:
    case True{}:
      SCon{Chr{c}, rest}
    case False{}:
      String.append(md.esc.c(c), rest)

# text as HTML text, before out
def md.esc(s: String, out: String) -> String:
  match s:
    case SNil{}:
      out
    case SCon{Chr{+c}, t}:
      md.esc.at(Bool.not(U32.is_eq(c, 38) || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, md.esc(t, out))

def md.hex(+n: U32) -> U32:
  Bool.pick(U32, U32.is_lt(n, 10), (n + 48 : U32), (n + 55 : U32))

def md.pct(+b: U32, rest: String) -> String:
  SCon{Chr{37}, SCon{Chr{md.hex(U32.shrn(b, 4n))}, SCon{Chr{md.hex(U32.and(b, 15))}, rest}}}

def md.pcts(bs: List<&2, U32>, rest: String) -> String:
  match bs:
    case Nil{}:
      rest
    case Con{+b, t}:
      md.pct(b, md.pcts(t, rest))

def md.utf8(+c: U32) -> List<&2, U32>:
  md.if(List<&2, U32>, U32.is_lt(c, 2048), u => [U32.or(192, U32.shrn(c, 6n)), U32.or(128, U32.and(c, 63))],
    u => md.if(List<&2, U32>, U32.is_lt(c, 65536), u => [U32.or(224, U32.shrn(c, 12n)), U32.or(128, U32.and(U32.shrn(c, 6n), 63)), U32.or(128, U32.and(c, 63))],
      u => [U32.or(240, U32.shrn(c, 18n)), U32.or(128, U32.and(U32.shrn(c, 12n), 63)), U32.or(128, U32.and(U32.shrn(c, 6n), 63)), U32.or(128, U32.and(c, 63))]))

# characters a link's target keeps as they are (houdini's HREF_SAFE)
def md.href.safe(+c: U32) -> Bool:
  (U32.is_ge(c, 48) && U32.is_le(c, 57)) || (U32.is_ge(c, 65) && U32.is_le(c, 90)) || (U32.is_ge(c, 97) && U32.is_le(c, 122))
    || U32.is_eq(c, 33) || U32.is_eq(c, 35) || U32.is_eq(c, 36) || U32.is_eq(c, 37) || U32.is_eq(c, 40) || U32.is_eq(c, 41) || U32.is_eq(c, 42)
    || U32.is_eq(c, 43) || U32.is_eq(c, 44) || U32.is_eq(c, 45) || U32.is_eq(c, 46) || U32.is_eq(c, 47) || U32.is_eq(c, 58) || U32.is_eq(c, 59)
    || U32.is_eq(c, 61) || U32.is_eq(c, 63) || U32.is_eq(c, 64) || U32.is_eq(c, 95) || U32.is_eq(c, 126)

def md.href.c(+c: U32, +rest: String) -> String:
  md.if(String, U32.is_eq(c, 38), u => String.append("&amp;", rest), u => md.if(String, U32.is_eq(c, 39), u => String.append("&#x27;", rest),
    u => md.if(String, md.href.safe(c), u => SCon{Chr{c}, rest},
      u => md.if(String, U32.is_lt(c, 128), u => md.pct(c, rest), u => md.pcts(md.utf8(c), rest)))))

# a link's target as cmark writes it in href
def md.href(s: String, out: String) -> String:
  match s:
    case SNil{}:
      out
    case SCon{Chr{+c}, t}:
      md.href.c(c, md.href(t, out))

# Writing inlines
# ---------------

def md.title(+t: String, +out: String) -> String:
  Bool.pick(String, String.is_empty(t), out, " title=\"" ++ md.esc(t, "\"" ++ out))

# The inlines xs as HTML, before out (hard: a soft break is a <br />, as
# cmark's HARDBREAKS has it)
def md.inl(xs: List<&2, md.I>, +hard: Bool, out: String) -> String:
  match xs:
    case Nil{}:
      out
    case Con{md.IText{s}, t}:
      md.esc(s, md.inl(t, hard, out))
    case Con{md.ICode{s}, t}:
      "<code>" ++ md.esc(s, "</code>" ++ md.inl(t, hard, out))
    case Con{md.ISoft{}, t}:
      Bool.pick(String, hard, "<br />\n", "\n") ++ md.inl(t, hard, out)
    case Con{md.IHard{}, t}:
      "<br />\n" ++ md.inl(t, hard, out)
    case Con{md.IEm{ks}, t}:
      "<em>" ++ md.inl(ks, hard, "</em>" ++ md.inl(t, hard, out))
    case Con{md.IStrong{ks}, t}:
      "<strong>" ++ md.inl(ks, hard, "</strong>" ++ md.inl(t, hard, out))
    case Con{md.IDel{ks}, t}:
      "<del>" ++ md.inl(ks, hard, "</del>" ++ md.inl(t, hard, out))
    case Con{md.ILink{u, ti, ks}, t}:
      "<a href=\"" ++ md.href(u, "\"" ++ md.title(ti, ">" ++ md.inl(ks, hard, "</a>" ++ md.inl(t, hard, out))))
    case Con{md.IRaw{h}, t}:
      h ++ md.inl(t, hard, out)

# Reading inlines
# ---------------

# A token: an inline read whole, or a run of * _ ~ that may open or close
# emphasis (its character, how many are left of it, how long it was)
type md.T is Data:
  md.TNode{i: md.I}
  md.TDelim{c: U32, n: Nat, len: Nat, open: Bool, close: Bool}

# what the reader has so far: the text not yet a token (reversed), the
# tokens (reversed)
type md.L is Data:
  md.L{txt: String, toks: List<&2, md.T>}

def md.l.flush(l: md.L) -> List<&2, md.T>:
  match l:
    case md.L{SNil{}, ts}:
      ts
    case md.L{SCon{h, t}, ts}:
      md.TNode{md.IText{String.reverse(SCon{h, t})}} <> ts

def md.l.c(+c: U32, l: md.L) -> md.L:
  match l:
    case md.L{txt, ts}:
      md.L{SCon{Chr{c}, txt}, ts}

def md.l.s(s: String, l: md.L) -> md.L:
  match l:
    case md.L{txt, ts}:
      md.L{String.append(String.reverse(s), txt), ts}

def md.l.tok(t: md.T, l: md.L) -> md.L:
  md.L{"", t <> md.l.flush(l)}

def md.l.node(i: md.I, l: md.L) -> md.L:
  md.l.tok(md.TNode{i}, l)

# a run of c: how many, and what follows
type md.Run is Data:
  md.Run{n: Nat, rest: String}

def md.run.at(hit: Bool, +c: U32, +n: Nat, +h: Char, +t: String, more: Unit -> md.Run) -> md.Run:
  match hit:
    case True{}:
      more(Unit{})
    case False{}:
      md.Run{n, SCon{h, t}}

def md.run(s: String, +c: U32, +n: Nat) -> md.Run:
  match s:
    case SNil{}:
      md.Run{n, ""}
    case SCon{Chr{+x}, +t}:
      md.run.at(U32.is_eq(x, c), c, n, Chr{x}, t, u => md.run(t, c, 1n+n))

def md.first(s: String) -> U32:
  match s:
    case SNil{}:
      10
    case SCon{Chr{c}, t}:
      c

# Code spans: the closing run of exactly k backticks
type md.Got is Data:
  md.Got{a: String, rest: String}

def md.code.at(close: Bool, +k: Nat, +j: Nat, +acc: String, +rest: String, more: String -> Maybe<&2, md.Got>) -> Maybe<&2, md.Got>:
  match close:
    case True{}:
      Some{md.Got{String.reverse(acc), rest}}
    case False{}:
      more(String.append(String.repeat("`", j), acc))

def md.code.run(r: md.Run, +k: Nat, +acc: String, more: String -> String -> Maybe<&2, md.Got>) -> Maybe<&2, md.Got>:
  match r:
    case md.Run{+j, +rest}:
      md.code.at(Nat.is_eq(j, k), k, j, acc, rest, a => more(rest, a))

def md.code.find(+fuel: Nat, s: String, +k: Nat, +acc: String) -> Maybe<&2, md.Got>:
  match fuel s:
    case 0n x:
      None{}
    case 1n+f SNil{}:
      None{}
    case 1n+f SCon{Chr{+c}, +t}:
      md.if(Maybe<&2, md.Got>, U32.is_eq(c, 96), u => md.code.run(md.run(t, 96, 1n), k, acc, r => a => md.code.find(f, r, k, a)),
        u => md.code.find(f, t, k, SCon{Chr{c}, acc}))

def md.nl.space(s: String) -> String:
  match s:
    case SNil{}:
      ""
    case SCon{Chr{+c}, t}:
      SCon{Chr{Bool.pick(U32, U32.is_eq(c, 10), 32, c)}, md.nl.space(t)}

def md.all.spaces(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{Chr{+c}, t}:
      U32.is_eq(c, 32) && md.all.spaces(t)

def md.code.trim(both: Bool, +s: String) -> String:
  Bool.pick(String, both, String.take(String.drop(s, 1n), Nat.sub(String.length(s), 2n)), s)
# a code span's text: line ends as spaces; one space off each end when both
# ends have one and it is not all spaces
def md.code.text(+s: String) -> String:
  md.code.trim(String.starts_with(s, " ") && String.ends_with(s, " ") && Bool.not(md.all.spaces(s)), s)


def md.delim.lr(+c: U32, +n: Nat, +p: U32, +x: U32, +left: Bool, +right: Bool) -> md.T:
  Bool.pick(md.T, U32.is_eq(c, 95),
    md.TDelim{c, n, n, left && (Bool.not(right) || md.punct(p)), right && (Bool.not(left) || md.punct(x))},
    md.TDelim{c, n, n, left, right})

# Delimiter runs: whether one may open and close emphasis (CommonMark's
# flanking rules; `_` also by what is on its outer side)
def md.delim(+c: U32, +n: Nat, +p: U32, +x: U32) -> md.T:
  md.delim.lr(c, n, p, x, Bool.not(md.white(x)) && (Bool.not(md.punct(x)) || md.white(p) || md.punct(p)),
    Bool.not(md.white(p)) && (Bool.not(md.punct(p)) || md.white(x) || md.punct(x)))

# Entities: &name;  &#ddd;  &#xhh;
def md.ents() -> List<&2, X.tx.Two>:
  [X.tx.Two{"amp", "&"}, X.tx.Two{"lt", "<"}, X.tx.Two{"gt", ">"}, X.tx.Two{"quot", "\""}, X.tx.Two{"apos", "'"},
   X.tx.Two{"nbsp", SCon{Chr{160}, ""}}, X.tx.Two{"copy", SCon{Chr{169}, ""}}, X.tx.Two{"reg", SCon{Chr{174}, ""}},
   X.tx.Two{"trade", SCon{Chr{8482}, ""}}, X.tx.Two{"hellip", SCon{Chr{8230}, ""}}, X.tx.Two{"mdash", SCon{Chr{8212}, ""}},
   X.tx.Two{"ndash", SCon{Chr{8211}, ""}}, X.tx.Two{"lsquo", SCon{Chr{8216}, ""}}, X.tx.Two{"rsquo", SCon{Chr{8217}, ""}},
   X.tx.Two{"ldquo", SCon{Chr{8220}, ""}}, X.tx.Two{"rdquo", SCon{Chr{8221}, ""}}, X.tx.Two{"bull", SCon{Chr{8226}, ""}},
   X.tx.Two{"middot", SCon{Chr{183}, ""}}, X.tx.Two{"times", SCon{Chr{215}, ""}}, X.tx.Two{"divide", SCon{Chr{247}, ""}},
   X.tx.Two{"deg", SCon{Chr{176}, ""}}, X.tx.Two{"plusmn", SCon{Chr{177}, ""}}, X.tx.Two{"larr", SCon{Chr{8592}, ""}},
   X.tx.Two{"rarr", SCon{Chr{8594}, ""}}, X.tx.Two{"uarr", SCon{Chr{8593}, ""}}, X.tx.Two{"darr", SCon{Chr{8595}, ""}},
   X.tx.Two{"harr", SCon{Chr{8596}, ""}}, X.tx.Two{"laquo", SCon{Chr{171}, ""}}, X.tx.Two{"raquo", SCon{Chr{187}, ""}},
   X.tx.Two{"euro", SCon{Chr{8364}, ""}}, X.tx.Two{"pound", SCon{Chr{163}, ""}}, X.tx.Two{"yen", SCon{Chr{165}, ""}},
   X.tx.Two{"cent", SCon{Chr{162}, ""}}, X.tx.Two{"sect", SCon{Chr{167}, ""}}, X.tx.Two{"para", SCon{Chr{182}, ""}},
   X.tx.Two{"shy", SCon{Chr{173}, ""}}, X.tx.Two{"ensp", SCon{Chr{8194}, ""}}, X.tx.Two{"emsp", SCon{Chr{8195}, ""}},
   X.tx.Two{"thinsp", SCon{Chr{8201}, ""}}, X.tx.Two{"check", SCon{Chr{10003}, ""}}, X.tx.Two{"le", SCon{Chr{8804}, ""}},
   X.tx.Two{"ge", SCon{Chr{8805}, ""}}, X.tx.Two{"ne", SCon{Chr{8800}, ""}}, X.tx.Two{"lambda", SCon{Chr{955}, ""}}]

def md.ent.find(es: List<&2, X.tx.Two>, +name: String) -> Maybe<&2, String>:
  match es:
    case Nil{}:
      None{}
    case Con{X.tx.Two{+k, +v}, t}:
      md.if(Maybe<&2, String>, String.eq(k, name), u => Some{v}, u => md.ent.find(t, name))

def md.alnum(+c: U32) -> Bool:
  (U32.is_ge(c, 48) && U32.is_le(c, 57)) || (U32.is_ge(c, 65) && U32.is_le(c, 90)) || (U32.is_ge(c, 97) && U32.is_le(c, 122))

def md.digit(+c: U32) -> Bool:
  U32.is_ge(c, 48) && U32.is_le(c, 57)

def md.hexd(+c: U32) -> Bool:
  (U32.is_ge(c, 48) && U32.is_le(c, 57)) || (U32.is_ge(c, 65) && U32.is_le(c, 70)) || (U32.is_ge(c, 97) && U32.is_le(c, 102))

def md.got.cons(+h: Char, g: md.Got) -> md.Got:
  match g:
    case md.Got{a, r}:
      md.Got{SCon{h, a}, r}

# the characters while ok, at most max of them: them and what follows
def md.span.at(take: Bool, +h: Char, +t: String, more: Unit -> md.Got) -> md.Got:
  match take:
    case True{}:
      md.got.cons(h, more(Unit{}))
    case False{}:
      md.Got{"", SCon{h, t}}

def md.span(~ok: @+c:U32 -> Bool, max: Nat, s: String) -> md.Got:
  match max s:
    case 0n x:
      md.Got{"", x}
    case 1n+m SNil{}:
      md.Got{"", ""}
    case 1n+m SCon{Chr{+c}, +t}:
      md.span.at(ok(c), Chr{c}, t, u => md.span(~ok, m, t))

def md.code.point(+n: Nat) -> String:
  Bool.pick(String, Nat.is_eq(n, 0n) || Nat.is_gt(n, 1114111n) || (Nat.is_ge(n, 55296n) && Nat.is_le(n, 57343n)), SCon{Chr{65533}, ""},
    SCon{Chr{U32.from_nat(n)}, ""})

def md.hexval(s: String, +n: Nat) -> Nat:
  match s:
    case SNil{}:
      n
    case SCon{Chr{+c}, t}:
      md.hexval(t, Nat.add(Nat.mul(n, 16n), U32.to_nat(Bool.pick(U32, U32.is_le(c, 57), (c - 48 : U32), Bool.pick(U32, U32.is_le(c, 70), (c - 55 : U32), (c - 87 : U32))))))

def md.decval(s: String, +n: Nat) -> Nat:
  match s:
    case SNil{}:
      n
    case SCon{Chr{+c}, t}:
      md.decval(t, Nat.add(Nat.mul(n, 10n), U32.to_nat((c - 48 : U32))))

def md.ent.close(ok: Bool, v: String, rest: String) -> Maybe<&2, md.Got>:
  match ok rest:
    case True{} SCon{Chr{59}, t}:
      Some{md.Got{v, t}}
    case x y:
      None{}

def md.ent.num(g: md.Got, hex: Bool) -> Maybe<&2, md.Got>:
  match g hex:
    case md.Got{+ds, r} True{}:
      md.ent.close(Bool.not(String.is_empty(ds)), md.code.point(md.hexval(ds, 0n)), r)
    case md.Got{+ds, r} False{}:
      md.ent.close(Bool.not(String.is_empty(ds)), md.code.point(md.decval(ds, 0n)), r)

def md.ent.named.at(m: Maybe<&2, String>, rest: String) -> Maybe<&2, md.Got>:
  match m:
    case None{}:
      None{}
    case Some{v}:
      md.ent.close(True{}, v, rest)

def md.ent.named(g: md.Got) -> Maybe<&2, md.Got>:
  match g:
    case md.Got{+name, r}:
      md.ent.named.at(md.ent.find(md.ents(), name), r)

# what an entity after "&" stands for, and what follows its ";"
def md.entity(s: String) -> Maybe<&2, md.Got>:
  match s:
    case SCon{Chr{35}, SCon{Chr{+x}, +t}}:
      md.if(Maybe<&2, md.Got>, U32.is_eq(x, 120) || U32.is_eq(x, 88), u => md.ent.num(md.span(~md.hexd, 6n, t), True{}),
        u => md.ent.num(md.span(~md.digit, 7n, SCon{Chr{x}, t}), False{}))
    case x:
      md.ent.named(md.span(~md.alnum, 32n, x))

# Autolinks <scheme:...> and <user@host>, and raw HTML (kept as text)
def md.angle.ok(+c: U32) -> Bool:
  Bool.not(U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_le(c, 32))

def md.scheme.c(+c: U32) -> Bool:
  md.alnum(c) || U32.is_eq(c, 43) || U32.is_eq(c, 46) || U32.is_eq(c, 45)

def md.letter(+c: U32) -> Bool:
  (U32.is_ge(c, 65) && U32.is_le(c, 90)) || (U32.is_ge(c, 97) && U32.is_le(c, 122))

def md.is.url.g(g: md.Got) -> Bool:
  match g:
    case md.Got{+sc, r}:
      Nat.is_ge(String.length(sc), 2n) && Nat.is_le(String.length(sc), 32n) && U32.is_eq(md.first(r), 58)

def md.is.url(+s: String) -> Bool:
  md.letter(md.first(s)) && md.is.url.g(md.span(~md.scheme.c, 40n, s))

def md.is.mail(+s: String) -> Bool:
  String.contains(s, "@") && Bool.not(String.starts_with(s, "@")) && Bool.not(String.ends_with(s, "@")) && String.contains(String.drop(s, 1n), ".")

def md.auto.got(g: md.Got) -> Maybe<&2, md.Got>:
  match g:
    case md.Got{+c, SCon{Chr{62}, +rest}}:
      md.if(Maybe<&2, md.Got>, md.is.url(c), u => Some{md.Got{c, rest}},
        u => Bool.pick(Maybe<&2, md.Got>, md.is.mail(c), Some{md.Got{"mailto:" ++ c, rest}}, None{}))
    case x:
      None{}

# an autolink after "<": its target and what follows its ">"
def md.auto(s: String) -> Maybe<&2, md.Got>:
  md.auto.got(md.span(~md.angle.ok, 4000n, s))

def md.tag.c(+c: U32) -> Bool:
  Bool.not(U32.is_eq(c, 62) || U32.is_eq(c, 60))

def md.tag.got(g: md.Got) -> Maybe<&2, md.Got>:
  match g:
    case md.Got{+t, SCon{Chr{62}, rest}}:
      Some{md.Got{"<" ++ t ++ ">", rest}}
    case x:
      None{}

def md.comment.go(fuel: Nat, s: String, +acc: String) -> Maybe<&2, md.Got>:
  match fuel s:
    case 0n x:
      None{}
    case 1n+f SNil{}:
      None{}
    case 1n+f SCon{+h, +t}:
      md.if(Maybe<&2, md.Got>, String.starts_with(SCon{h, t}, "-->"), u => Some{md.Got{String.reverse(acc) ++ "-->", String.drop(t, 2n)}},
        u => md.comment.go(f, t, SCon{h, acc}))

# raw HTML after "<" (a tag, or a comment): itself and what follows
def md.raw(+s: String) -> Maybe<&2, md.Got>:
  md.if(Maybe<&2, md.Got>, String.starts_with(s, "!--"), u => md.comment.go(String.length(s), String.drop(s, 3n), "--!<"),
    u => md.if(Maybe<&2, md.Got>, md.letter(md.first(s)) || (String.starts_with(s, "/") && md.letter(md.first(String.drop(s, 1n)))),
      u => md.tag.got(md.span(~md.tag.c, 4000n, s)), u => None{}))

# Links: [text](target "title")
def md.brk.at(close: Bool, open: Bool, +depth: Nat, +h: Char, +t: String, +acc: String, more: Nat -> String -> Maybe<&2, md.Got>) -> Maybe<&2, md.Got>:
  match close open:
    case True{} x:
      md.if(Maybe<&2, md.Got>, Nat.is_eq(depth, 0n), u => Some{md.Got{String.reverse(acc), t}}, u => more(Nat.sub(depth, 1n), SCon{h, acc}))
    case False{} True{}:
      more(1n+depth, SCon{h, acc})
    case False{} False{}:
      more(depth, SCon{h, acc})

# the text up to the "]" that closes the "[" before s, and what follows it
def md.brk(+fuel: Nat, s: String, +depth: Nat, +acc: String) -> Maybe<&2, md.Got>:
  match fuel s:
    case 0n x:
      None{}
    case 1n+f SNil{}:
      None{}
    case 1n+f SCon{Chr{92}, SCon{+x, +t}}:
      md.brk(f, t, depth, SCon{x, SCon{Chr{92}, acc}})
    case 1n+f SCon{Chr{+c}, +t}:
      md.brk.at(U32.is_eq(c, 93), U32.is_eq(c, 91), depth, Chr{c}, t, acc, d => a => md.brk(f, t, d, a))

type md.Dest is Data:
  md.Dest{url: String, title: String, rest: String}

def md.skip.ws(s: String) -> String:
  match s:
    case SNil{}:
      ""
    case SCon{Chr{+c}, +t}:
      md.if(String, U32.is_eq(c, 32) || U32.is_eq(c, 9) || U32.is_eq(c, 10), u => md.skip.ws(t), u => SCon{Chr{c}, t})

# backslashes before punctuation dropped
def md.unesc(s: String) -> String:
  match s:
    case SCon{Chr{92}, SCon{Chr{+x}, +t}}:
      md.if(String, md.ascii.punct(x), u => SCon{Chr{x}, md.unesc(t)}, u => SCon{Chr{92}, md.unesc(SCon{Chr{x}, t})})
    case SCon{h, t}:
      SCon{h, md.unesc(t)}
    case SNil{}:
      ""

def md.depth.of(+c: U32, +d: Nat) -> Nat:
  Bool.pick(Nat, U32.is_eq(c, 40), 1n+d, Bool.pick(Nat, U32.is_eq(c, 41), Nat.sub(d, 1n), d))

def md.dest.raw.at(stop: Bool, +depth: Nat, +c: U32, +t: String, +acc: String, more: Nat -> String -> Maybe<&2, md.Got>) -> Maybe<&2, md.Got>:
  match stop:
    case True{}:
      Some{md.Got{String.reverse(acc), SCon{Chr{c}, t}}}
    case False{}:
      more(md.depth.of(c, depth), SCon{Chr{c}, acc})

# a target written bare: up to white space, or a ")" that closes nothing
def md.dest.raw(+fuel: Nat, s: String, +depth: Nat, +acc: String) -> Maybe<&2, md.Got>:
  match fuel s:
    case 0n x:
      None{}
    case 1n+f SNil{}:
      Some{md.Got{String.reverse(acc), ""}}
    case 1n+f SCon{Chr{92}, SCon{Chr{+x}, +t}}:
      md.dest.raw(f, t, depth, SCon{Chr{x}, SCon{Chr{92}, acc}})
    case 1n+f SCon{Chr{+c}, +t}:
      md.dest.raw.at(U32.is_le(c, 32) || (U32.is_eq(c, 41) && Nat.is_eq(depth, 0n)), depth, c, t, acc, d => a => md.dest.raw(f, t, d, a))

def md.title.close(+q: U32) -> U32:
  Bool.pick(U32, U32.is_eq(q, 40), 41, q)

def md.title.at(hit: Bool, +q: U32, +h: Char, +t: String, +acc: String, more: String -> Maybe<&2, md.Got>) -> Maybe<&2, md.Got>:
  match hit:
    case True{}:
      Some{md.Got{String.reverse(acc), t}}
    case False{}:
      more(SCon{h, acc})

# a title's text, up to its closing quote (q), and what follows
def md.title.go(+fuel: Nat, s: String, +q: U32, +acc: String) -> Maybe<&2, md.Got>:
  match fuel s:
    case 0n x:
      None{}
    case 1n+f SNil{}:
      None{}
    case 1n+f SCon{Chr{92}, SCon{+x, +t}}:
      md.title.go(f, t, q, SCon{x, SCon{Chr{92}, acc}})
    case 1n+f SCon{Chr{+c}, +t}:
      md.title.at(U32.is_eq(c, q), q, Chr{c}, t, acc, a => md.title.go(f, t, q, a))

def md.dest.end(+url: String, +title: String, s: String) -> Maybe<&2, md.Dest>:
  match s:
    case SCon{Chr{41}, t}:
      Some{md.Dest{md.unesc(url), md.unesc(title), t}}
    case x:
      None{}

def md.dest.title.got(+url: String, m: Maybe<&2, md.Got>) -> Maybe<&2, md.Dest>:
  match m:
    case None{}:
      None{}
    case Some{md.Got{+ti, r}}:
      md.dest.end(url, ti, md.skip.ws(r))

def md.dest.title(+url: String, +s: String) -> Maybe<&2, md.Dest>:
  md.if(Maybe<&2, md.Dest>, U32.is_eq(md.first(s), 34) || U32.is_eq(md.first(s), 39) || U32.is_eq(md.first(s), 40),
    u => md.dest.title.got(url, md.title.go(String.length(s), String.drop(s, 1n), md.title.close(md.first(s)), "")),
    u => md.dest.end(url, "", s))

def md.dest.got(m: Maybe<&2, md.Got>) -> Maybe<&2, md.Dest>:
  match m:
    case None{}:
      None{}
    case Some{md.Got{+url, r}}:
      md.dest.title(url, md.skip.ws(r))

def md.dest.angle(g: md.Got) -> Maybe<&2, md.Got>:
  match g:
    case md.Got{+u, SCon{Chr{62}, rest}}:
      Some{md.Got{u, rest}}
    case x:
      None{}

def md.not.angle.nl(+c: U32) -> Bool:
  Bool.not(U32.is_eq(c, 62) || U32.is_eq(c, 60) || U32.is_eq(c, 10))

def md.dest.at(+s: String) -> Maybe<&2, md.Dest>:
  md.if(Maybe<&2, md.Dest>, String.starts_with(s, "<"), u => md.dest.got(md.dest.angle(md.span(~md.not.angle.nl, 4000n, String.drop(s, 1n)))),
    u => md.dest.got(md.dest.raw(String.length(s), s, 0n, "")))

# after "](": the target, the title, and what follows the ")"
def md.dest(+s: String) -> Maybe<&2, md.Dest>:
  md.dest.at(md.skip.ws(s))

# GitHub's bare links: www.x, http://x, https://x after white space or *_~(
def md.trail.drop(+c: U32) -> Bool:
  String.contains("?!.,:*_~'\"", SCon{Chr{c}, ""})

def md.count(s: String, +c: U32, +n: Nat) -> Nat:
  match s:
    case SNil{}:
      n
    case SCon{Chr{+x}, t}:
      md.count(t, c, Bool.pick(Nat, U32.is_eq(x, c), 1n+n, n))

def md.ent.tail.g(g: md.Got) -> String:
  match g:
    case md.Got{a, SCon{Chr{38}, t}}:
      t
    case md.Got{a, r}:
      ""

def md.ent.tail(r: String) -> String:
  md.ent.tail.g(md.span(~md.alnum, 40n, r))

# a bare link's end: trailing punctuation dropped, a ")" it does not open,
# an entity at its end (on its reversed text r)
def md.trim.go(+fuel: Nat, +r: String) -> String:
  match fuel:
    case 0n:
      r
    case 1n+f:
      md.if(String, String.is_empty(r), u => r,
        u => md.if(String, md.trail.drop(md.first(r)), u => md.trim.go(f, String.drop(r, 1n)),
          u => md.if(String, U32.is_eq(md.first(r), 41) && Nat.is_gt(md.count(r, 41, 0n), md.count(r, 40, 0n)), u => md.trim.go(f, String.drop(r, 1n)),
            u => md.if(String, U32.is_eq(md.first(r), 59) && Bool.not(String.is_empty(md.ent.tail(String.drop(r, 1n)))), u => md.trim.go(f, md.ent.tail(String.drop(r, 1n))),
              u => r))))

def md.link.c(+c: U32) -> Bool:
  Bool.not(md.white(c) || U32.is_eq(c, 60))

def md.domain.c(+c: U32) -> Bool:
  md.alnum(c) || U32.is_eq(c, 45) || U32.is_eq(c, 95) || U32.is_eq(c, 46)

# a bare link at s (www: it starts "www."): its target, its text, and what
# follows it
type md.Bare is Data:
  md.Bare{href: String, text: String, rest: String}

def md.got.a(g: md.Got) -> String:
  match g:
    case md.Got{a, r}:
      a

def md.bare.dom(+www: Bool, +l: String) -> String:
  md.got.a(md.span(~md.domain.c, 300n, String.drop(l, Bool.pick(Nat, www, 4n, Bool.pick(Nat, String.starts_with(l, "https://"), 8n, Bool.pick(Nat, String.starts_with(l, "ftp://"), 6n, 7n))))))

def md.bare.got(+www: Bool, +all: String, +l: String) -> Maybe<&2, md.Bare>:
  md.if(Maybe<&2, md.Bare>, String.is_empty(l) || String.is_empty(md.bare.dom(www, l)), u => None{},
    u => Some{md.Bare{Bool.pick(String, www, "http://" ++ l, l), l, String.drop(all, String.length(l))}})

def md.bare(+www: Bool, +s: String) -> Maybe<&2, md.Bare>:
  md.bare.got(www, s, String.reverse(md.trim.go(64n, String.reverse(md.got.a(md.span(~md.link.c, 4000n, s))))))

# Emphasis (CommonMark's process_emphasis, on a stack)
# ---------------------------------------------------

type md.S is Data:
  md.SNode{i: md.I}
  md.SDelim{c: U32, n: Nat, len: Nat, open: Bool, close: Bool}

def md.chars(+c: U32, n: Nat) -> String:
  String.repeat(SCon{Chr{c}, ""}, n)

def md.s.node(s: md.S) -> md.I:
  match s:
    case md.SNode{i}:
      i
    case md.SDelim{+c, n, l, o, cl}:
      md.IText{md.chars(c, n)}

# items in order as inlines
def md.s.list(xs: List<&2, md.S>) -> List<&2, md.I>:
  match xs:
    case Nil{}:
      []
    case Con{x, t}:
      md.s.node(x) <> md.s.list(t)

# a stack (newest first) as inlines, oldest first
def md.s.out(st: List<&2, md.S>, acc: List<&2, md.I>) -> List<&2, md.I>:
  match st:
    case Nil{}:
      acc
    case Con{x, t}:
      md.s.out(t, md.s.node(x) <> acc)

def md.merge.flush(m: Maybe<&2, String>, rest: List<&2, md.I>) -> List<&2, md.I>:
  match m:
    case None{}:
      rest
    case Some{s}:
      md.IText{s} <> rest

def md.merge.add(m: Maybe<&2, String>, s: String) -> Maybe<&2, String>:
  match m:
    case None{}:
      Some{s}
    case Some{a}:
      Some{String.append(a, s)}

# neighbouring texts joined
def md.merge.go(xs: List<&2, md.I>, m: Maybe<&2, String>) -> List<&2, md.I>:
  match xs:
    case Nil{}:
      md.merge.flush(m, [])
    case Con{md.IText{s}, t}:
      md.merge.go(t, md.merge.add(m, s))
    case Con{x, t}:
      md.merge.flush(m, x <> md.merge.go(t, None{}))

def md.merge(xs: List<&2, md.I>) -> List<&2, md.I>:
  md.merge.go(xs, None{})

# an opener searched for: found (the stack below it, the items between it
# and the closer, oldest first, and it) or not (the stack as it was)
type md.F is Data:
  md.Found{below: List<&2, md.S>, between: List<&2, md.S>, n: Nat, len: Nat, open: Bool, close: Bool}
  md.Lost{st: List<&2, md.S>}

# CommonMark's rule of 3
def md.rule3(+ol: Nat, +oc: Bool, +cl: Nat, +co: Bool) -> Bool:
  Bool.not((oc || co) && Nat.is_eq(Nat.mod(Nat.add(ol, cl), 3n), 0n) && Bool.not(Nat.is_eq(Nat.mod(ol, 3n), 0n) && Nat.is_eq(Nat.mod(cl, 3n), 0n)))

def md.find.at(hit: Bool, +c: U32, +n2: Nat, +l2: Nat, +o2: Bool, +cl2: Bool, below: List<&2, md.S>, between: List<&2, md.S>, more: List<&2, md.S> -> md.F) -> md.F:
  match hit:
    case True{}:
      md.Found{below, between, n2, l2, o2, cl2}
    case False{}:
      more(md.SDelim{c, n2, l2, o2, cl2} <> between)

def md.find(st: List<&2, md.S>, +c: U32, +n: Nat, +len: Nat, +co: Bool, between: List<&2, md.S>) -> md.F:
  match st:
    case Nil{}:
      md.Lost{List.reverse(&2, md.S, between)}
    case Con{md.SDelim{+c2, +n2, +l2, +o2, +cl2}, +t}:
      md.find.at(U32.is_eq(c2, c) && o2 && md.rule3(l2, cl2, len, co) && (Bool.not(U32.is_eq(c, 126)) || Nat.is_eq(n2, n)),
        c2, n2, l2, o2, cl2, t, between, b => md.find(t, c, n, len, co, b))
    case Con{x, t}:
      md.find(t, c, n, len, co, x <> between)

def md.wrap(+c: U32, +k: Nat, +xs: List<&2, md.I>) -> md.I:
  Bool.pick(md.I, U32.is_eq(c, 126), md.IDel{xs}, Bool.pick(md.I, Nat.is_eq(k, 2n), md.IStrong{xs}, md.IEm{xs}))

def md.close.found(+c: U32, +n: Nat, +k: Nat, +below: List<&2, md.S>, between: List<&2, md.S>, +n2: Nat, +l2: Nat, +o2: Bool, +cl2: Bool, more: Nat -> List<&2, md.S> -> List<&2, md.S>) -> List<&2, md.S>:
  more(Nat.sub(n, k), md.SNode{md.wrap(c, k, md.merge(md.s.list(between)))}
    <> md.if(List<&2, md.S>, Nat.is_gt(n2, k), u => md.SDelim{c, Nat.sub(n2, k), l2, o2, cl2} <> below, u => below))

def md.close.f(r: md.F, +c: U32, +n: Nat, +len: Nat, +co: Bool, +cl: Bool, more: Nat -> List<&2, md.S> -> List<&2, md.S>) -> List<&2, md.S>:
  match r:
    case md.Found{below, between, +n2, +l2, +o2, +cl2}:
      md.close.found(c, n, Bool.pick(Nat, U32.is_eq(c, 126), n, Bool.pick(Nat, Nat.is_ge(n, 2n) && Nat.is_ge(n2, 2n), 2n, 1n)), below, between, n2, l2, o2, cl2, more)
    case md.Lost{+st}:
      Bool.pick(List<&2, md.S>, co, md.SDelim{c, n, len, co, cl} <> st, md.SNode{md.IText{md.chars(c, n)}} <> st)

# a closing run of c (n of it left) against the stack
def md.close(+fuel: Nat, +c: U32, +n: Nat, +len: Nat, +co: Bool, +cl: Bool, +st: List<&2, md.S>) -> List<&2, md.S>:
  match fuel:
    case 0n:
      st
    case 1n+f:
      md.if(List<&2, md.S>, Nat.is_eq(n, 0n), u => st,
        u => md.close.f(md.find(st, c, n, len, co, []), c, n, len, co, cl, m => s => md.close(f, c, m, len, co, cl, s)))

def md.delim.push(+c: U32, +n: Nat, +len: Nat, +o: Bool, +cl: Bool, st: List<&2, md.S>) -> List<&2, md.S>:
  match cl:
    case True{}:
      md.close(n, c, n, len, o, cl, st)
    case False{}:
      md.SDelim{c, n, len, o, cl} <> st

def md.emph.go(ts: List<&2, md.T>, st: List<&2, md.S>) -> List<&2, md.I>:
  match ts:
    case Nil{}:
      md.merge(md.s.out(st, []))
    case Con{md.TNode{i}, t}:
      md.emph.go(t, md.SNode{i} <> st)
    case Con{md.TDelim{+c, +n, +len, +o, +cl}, t}:
      md.emph.go(t, md.delim.push(c, n, len, o, cl, st))

# the tokens read, emphasis matched
def md.emph(ts: List<&2, md.T>) -> List<&2, md.I>:
  md.emph.go(ts, [])

# The reader's steps
# ------------------

# What the text at the reader's place is: plain text, an inline read whole,
# a delimiter run, a link (its inner text still to read), a line's end, or
# the end; each with what follows and the last character read.
type md.Step is Data:
  md.PText{s: String, rest: String, prev: U32}
  md.PNode{i: md.I, rest: String, prev: U32}
  md.PTok{t: md.T, rest: String, prev: U32}
  md.PLink{url: String, title: String, inner: String, rest: String, prev: U32}
  md.PBreak{rest: String}
  md.PEnd{}

def md.special(+c: U32) -> Bool:
  U32.is_eq(c, 92) || U32.is_eq(c, 96) || U32.is_eq(c, 42) || U32.is_eq(c, 95) || U32.is_eq(c, 126) || U32.is_eq(c, 91) || U32.is_eq(c, 33)
    || U32.is_eq(c, 60) || U32.is_eq(c, 38) || U32.is_eq(c, 10) || U32.is_eq(c, 40) || md.white(c)

def md.plain(+c: U32) -> Bool:
  Bool.not(md.special(c))

def md.skip.sp(s: String) -> String:
  match s:
    case SCon{Chr{+c}, +t}:
      md.if(String, U32.is_eq(c, 32) || U32.is_eq(c, 9), u => md.skip.sp(t), u => SCon{Chr{c}, t})
    case SNil{}:
      ""

def md.last(+s: String, +d: U32) -> U32:
  md.first(String.reverse(SCon{Chr{d}, s}))

# "\": a hard break at a line's end, a punctuation character as itself, else itself
def md.step.bs(t: String) -> md.Step:
  match t:
    case SCon{Chr{10}, r}:
      md.PNode{md.IHard{}, md.skip.sp(r), 10}
    case SCon{Chr{+x}, +r}:
      md.if(md.Step, md.ascii.punct(x), u => md.PText{SCon{Chr{x}, ""}, r, x}, u => md.PText{"\\", SCon{Chr{x}, r}, 92})
    case SNil{}:
      md.PText{"\\", "", 92}

def md.step.code.got(+k: Nat, +rest: String, m: Maybe<&2, md.Got>) -> md.Step:
  match m:
    case Some{md.Got{c, r}}:
      md.PNode{md.ICode{md.code.text(md.nl.space(c))}, r, 96}
    case None{}:
      md.PText{md.chars(96, k), rest, 96}

def md.step.code(r: md.Run) -> md.Step:
  match r:
    case md.Run{+k, +rest}:
      md.step.code.got(k, rest, md.code.find(1n+String.length(rest), rest, k, ""))

def md.step.delim(+c: U32, +prev: U32, r: md.Run) -> md.Step:
  match r:
    case md.Run{+n, +rest}:
      md.if(md.Step, U32.is_eq(c, 126) && Nat.is_gt(n, 2n), u => md.PText{md.chars(c, n), rest, c},
        u => md.PTok{md.delim(c, n, prev, md.first(rest)), rest, c})

def md.step.link.dest(+bang: String, +inner: String, +after: String, m: Maybe<&2, md.Dest>) -> md.Step:
  match m:
    case Some{md.Dest{u, ti, r}}:
      md.PLink{u, ti, inner, r, 41}
    case None{}:
      md.PText{bang ++ "[", inner ++ "]" ++ after, 91}

def md.step.link.got(+bang: String, +t: String, m: Maybe<&2, md.Got>) -> md.Step:
  match m:
    case Some{md.Got{+inner, +r}}:
      md.if(md.Step, String.starts_with(r, "("), u => md.step.link.dest(bang, inner, r, md.dest(String.drop(r, 1n))),
        u => md.PText{bang ++ "[", t, 91})
    case None{}:
      md.PText{bang ++ "[", t, 91}

# "[" (bang: "!" before it, an image, shown as a link)
def md.step.link(+bang: String, +t: String) -> md.Step:
  md.step.link.got(bang, t, md.brk(1n+String.length(t), t, 0n, ""))

def md.step.raw(+t: String, m: Maybe<&2, md.Got>) -> md.Step:
  match m:
    case Some{md.Got{h, r}}:
      md.PText{h, r, 62}
    case None{}:
      md.PText{"<", t, 60}

def md.mail.text(+u: String) -> String:
  Bool.pick(String, String.starts_with(u, "mailto:"), String.drop(u, 7n), u)

def md.step.lt.got(+t: String, m: Maybe<&2, md.Got>) -> md.Step:
  match m:
    case Some{md.Got{+u, r}}:
      md.PNode{md.ILink{u, "", [md.IText{md.mail.text(u)}]}, r, 62}
    case None{}:
      md.step.raw(t, md.raw(t))

def md.step.amp(+t: String, m: Maybe<&2, md.Got>) -> md.Step:
  match m:
    case Some{md.Got{v, r}}:
      md.PText{v, r, 59}
    case None{}:
      md.PText{"&", t, 38}

def md.step.bare(+c: U32, +t: String, m: Maybe<&2, md.Bare>) -> md.Step:
  match m:
    case Some{md.Bare{h, x, r}}:
      md.PNode{md.ILink{h, "", [md.IText{x}]}, r, 46}
    case None{}:
      md.PText{SCon{Chr{c}, ""}, t, c}

def md.bare.prev(+p: U32) -> Bool:
  md.white(p) || U32.is_eq(p, 42) || U32.is_eq(p, 95) || U32.is_eq(p, 126) || U32.is_eq(p, 40)

def md.scheme.at(+s: String) -> Bool:
  String.starts_with(s, "http://") || String.starts_with(s, "https://") || String.starts_with(s, "ftp://")

# where a bare link may start: www. after white space or *_~(; a URL after
# anything but a letter (cmark-gfm reads its scheme back to the first
# non-letter)
def md.bare.here(+p: U32, +s: String) -> Bool:
  (md.bare.prev(p) && String.starts_with(s, "www.")) || (Bool.not(md.letter(p)) && md.scheme.at(s))

def md.cut.bare.at(hit: Bool, +h: Char, +t: String, +acc: String, more: String -> md.Got) -> md.Got:
  match hit:
    case True{}:
      md.Got{String.reverse(acc), SCon{h, t}}
    case False{}:
      more(SCon{h, acc})

# a run of plain text cut before a bare link in it (p: the character before)
def md.cut.bare(s: String, +p: U32, +acc: String) -> md.Got:
  match s:
    case SNil{}:
      md.Got{String.reverse(acc), ""}
    case SCon{Chr{+c}, +t}:
      md.cut.bare.at(Bool.not(String.is_empty(acc)) && md.bare.here(p, SCon{Chr{c}, t}), Chr{c}, t, acc, a => md.cut.bare(t, c, a))

def md.step.plain.g(g: md.Got, +after: String) -> md.Step:
  match g:
    case md.Got{+s, +r}:
      md.PText{s, String.append(r, after), md.last(s, 32)}

def md.step.plain(+prev: U32, g: md.Got) -> md.Step:
  match g:
    case md.Got{+s, +r}:
      md.step.plain.g(md.cut.bare(s, prev, ""), r)

def md.step.word(+c: U32, +t: String, +prev: U32) -> md.Step:
  md.if(md.Step, md.bare.here(prev, SCon{Chr{c}, t}),
    u => md.step.bare(c, t, md.bare(String.starts_with(SCon{Chr{c}, t}, "www."), SCon{Chr{c}, t})),
    u => md.step.plain(prev, md.span(~md.plain, 100000n, SCon{Chr{c}, t})))

def md.next.c(+c: U32, +t: String, +prev: U32) -> md.Step:
  md.if(md.Step, U32.is_eq(c, 92), u => md.step.bs(t),
  u => md.if(md.Step, U32.is_eq(c, 96), u => md.step.code(md.run(t, 96, 1n)),
  u => md.if(md.Step, U32.is_eq(c, 42) || U32.is_eq(c, 95) || U32.is_eq(c, 126), u => md.step.delim(c, prev, md.run(t, c, 1n)),
  u => md.if(md.Step, U32.is_eq(c, 91), u => md.step.link("", t),
  u => md.if(md.Step, U32.is_eq(c, 33) && U32.is_eq(md.first(t), 91), u => md.step.link("!", String.drop(t, 1n)),
  u => md.if(md.Step, U32.is_eq(c, 60), u => md.step.lt.got(t, md.auto(t)),
  u => md.if(md.Step, U32.is_eq(c, 38), u => md.step.amp(t, md.entity(t)),
  u => md.if(md.Step, U32.is_eq(c, 10), u => md.PBreak{md.skip.sp(t)},
  u => md.if(md.Step, md.special(c), u => md.PText{SCon{Chr{c}, ""}, t, c},
  u => md.step.word(c, t, prev))))))))))

# the step at s, after prev
def md.next(s: String, +prev: U32) -> md.Step:
  match s:
    case SNil{}:
      md.PEnd{}
    case SCon{Chr{+c}, +t}:
      md.next.c(c, t, prev)

# a line's end: a hard break after two spaces, else a soft one; the spaces
# before it dropped
def md.l.brk.sp(s: String, +n: Nat) -> md.Got:
  match s:
    case SCon{Chr{32}, t}:
      md.l.brk.sp(t, 1n+n)
    case x:
      md.Got{Nat.show(n), x}

def md.l.brk.g(g: md.Got, ts: List<&2, md.T>) -> md.L:
  match g:
    case md.Got{+n, txt}:
      md.L{"", md.TNode{Bool.pick(md.I, Nat.is_ge(Maybe.default(&2, Nat, Nat.read(n), 0n), 2n), md.IHard{}, md.ISoft{})} <> md.l.flush(md.L{txt, ts})}

def md.l.brk(l: md.L) -> md.L:
  match l:
    case md.L{txt, ts}:
      md.l.brk.g(md.l.brk.sp(txt, 0n), ts)

def md.l.done(l: md.L) -> List<&2, md.T>:
  List.reverse(&2, md.T, md.l.flush(l))

# The reader: steps until the end (fuel: the text's length, as every step
# reads a character at least)
def md.lex(+fuel: Nat, st: md.Step, l: md.L) -> List<&2, md.T>:
  match fuel st:
    case 0n x:
      md.l.done(l)
    case 1n+f md.PEnd{}:
      md.l.done(l)
    case 1n+f md.PText{s, r, +p}:
      md.lex(f, md.next(r, p), md.l.s(s, l))
    case 1n+f md.PNode{i, r, +p}:
      md.lex(f, md.next(r, p), md.l.node(i, l))
    case 1n+f md.PTok{tk, r, +p}:
      md.lex(f, md.next(r, p), md.l.tok(tk, l))
    case 1n+f md.PLink{u, ti, inner, r, +p}:
      md.lex(f, md.next(r, p), md.l.node(md.ILink{u, ti, md.emph(md.lex(f, md.next(inner, 91), md.L{"", []}))}, l))
    case 1n+f md.PBreak{r}:
      md.lex(f, md.next(r, 10), md.l.brk(l))

# GitHub's bare e-mail addresses (cmark-gfm finds them in text nodes, after
# the rest is read): a local part, "@", a domain with a "." in it
def md.local.c(+c: U32) -> Bool:
  md.alnum(c) || U32.is_eq(c, 46) || U32.is_eq(c, 43) || U32.is_eq(c, 45) || U32.is_eq(c, 95)

def md.dots(s: String) -> Nat:
  match s:
    case SCon{Chr{46}, SCon{Chr{+c}, +t}}:
      Nat.add(Bool.pick(Nat, md.alnum(c), 1n, 0n), md.dots(SCon{Chr{c}, t}))
    case SCon{h, t}:
      md.dots(t)
    case SNil{}:
      0n

def md.mail.ok(+local: String, +dom: String) -> Bool:
  Bool.not(String.is_empty(local)) && Bool.not(String.is_empty(dom)) && Nat.is_gt(md.dots(dom), 0n)
    && (md.letter(md.first(String.reverse(dom))) || U32.is_eq(md.first(String.reverse(dom)), 46))

def md.mail.trim(+dom: String) -> String:
  String.reverse(md.trim.go(64n, String.reverse(dom)))

def md.mail.at(ok: Bool, +pre: String, +local: String, +dom: String, +rest: String, more: String -> List<&2, md.I>) -> List<&2, md.I>:
  match ok:
    case True{}:
      md.IText{pre} <> (md.ILink{"mailto:" ++ local ++ "@" ++ md.mail.trim(dom), "", [md.IText{local ++ "@" ++ md.mail.trim(dom)}]}
        <> more(String.drop(dom, String.length(md.mail.trim(dom))) ++ rest))
    case False{}:
      md.IText{pre ++ local ++ "@"} <> more(dom ++ rest)

def md.mail.dom(+pre: String, +local: String, g: md.Got, more: String -> List<&2, md.I>) -> List<&2, md.I>:
  match g:
    case md.Got{+dom, +rest}:
      md.mail.at(md.mail.ok(local, md.mail.trim(dom)), pre, local, dom, rest, more)

def md.got.rest(g: md.Got) -> String:
  match g:
    case md.Got{a, r}:
      r

def md.mail.local(+before: String, +from: String, more: String -> List<&2, md.I>) -> List<&2, md.I>:
  md.mail.dom(String.reverse(md.got.rest(md.span(~md.local.c, 1000n, String.reverse(before)))),
    String.reverse(md.got.a(md.span(~md.local.c, 1000n, String.reverse(before)))),
    md.span(~md.domain.c, 1000n, String.drop(from, 1n)), more)

def md.mail.two(p: X.tx.Two, more: String -> List<&2, md.I>) -> List<&2, md.I>:
  match p:
    case X.tx.Two{+before, +from}:
      md.if(List<&2, md.I>, String.is_empty(from), u => [md.IText{before}], u => md.mail.local(before, from, more))

def md.mails.go(fuel: Nat, +s: String) -> List<&2, md.I>:
  match fuel:
    case 0n:
      [md.IText{s}]
    case 1n+f:
      md.mail.two(X.tx.break.on("@", s), r => md.mails.go(f, r))

def md.mails(xs: List<&2, md.I>) -> List<&2, md.I>:
  match xs:
    case Nil{}:
      []
    case Con{md.IText{+s}, t}:
      List.append(&2, md.I, md.if(List<&2, md.I>, String.contains(s, "@"), u => md.mails.go(String.length(s), s), u => [md.IText{s}]), md.mails(t))
    case Con{md.IEm{ks}, t}:
      md.IEm{md.mails(ks)} <> md.mails(t)
    case Con{md.IStrong{ks}, t}:
      md.IStrong{md.mails(ks)} <> md.mails(t)
    case Con{md.IDel{ks}, t}:
      md.IDel{md.mails(ks)} <> md.mails(t)
    case Con{x, t}:
      x <> md.mails(t)

# a paragraph's (or a heading's, or a cell's) text as inlines
def md.inline(+s: String) -> List<&2, md.I>:
  md.merge(md.mails(md.emph(md.lex(1n+String.length(s), md.next(s, 10), md.L{"", []}))))

# Lines
# -----

# a line's indentation in columns (a tab to the next multiple of 4) and what
# follows it
type md.Ind is Data:
  md.Ind{cols: Nat, rest: String}

def md.ind.go(s: String, +n: Nat) -> md.Ind:
  match s:
    case SCon{Chr{32}, t}:
      md.ind.go(t, 1n+n)
    case SCon{Chr{9}, t}:
      md.ind.go(t, Nat.mul(Nat.add(Nat.div(n, 4n), 1n), 4n))
    case x:
      md.Ind{n, x}

def md.ind(s: String) -> md.Ind:
  md.ind.go(s, 0n)

def md.ind.n(i: md.Ind) -> Nat:
  match i:
    case md.Ind{n, r}:
      n

def md.ind.r(i: md.Ind) -> String:
  match i:
    case md.Ind{n, r}:
      r

def md.cols(+s: String) -> Nat:
  md.ind.n(md.ind(s))

def md.unind(+s: String) -> String:
  md.ind.r(md.ind(s))

def md.blank(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{Chr{+c}, t}:
      md.white(c) && md.blank(t)

# up to n columns of indentation taken off a line
def md.dedent.go(s: String, n: Nat) -> String:
  match s n:
    case x 0n:
      x
    case SCon{Chr{32}, t} 1n+p:
      md.dedent.go(t, p)
    case SCon{Chr{9}, t} 1n+p:
      md.dedent.go(t, Nat.sub(p, 3n))
    case x 1n+p:
      x

def md.dedent(n: Nat, s: String) -> String:
  md.dedent.go(s, n)

def md.join(ls: List<&2, String>) -> String:
  String.join(ls, "\n")

# each line ended by "\n"
def md.body(ls: List<&2, String>) -> String:
  match ls:
    case Nil{}:
      ""
    case Con{l, t}:
      l ++ "\n" ++ md.body(t)

# the leading blank lines of lines dropped
def md.drop.blank(ls: List<&2, String>) -> List<&2, String>:
  match ls:
    case Con{+l, +t}:
      md.if(List<&2, String>, md.blank(l), u => md.drop.blank(t), u => l <> t)
    case Nil{}:
      []

def md.trim.blank(ls: List<&2, String>) -> List<&2, String>:
  List.reverse(&2, String, md.drop.blank(List.reverse(&2, String, ls)))

# Block starts (on a line's text after its indentation, 3 columns at most)
# ------------------------------------------------------------------------

def md.only(s: String, +c: U32, +n: Nat) -> Nat:
  match s:
    case SNil{}:
      n
    case SCon{Chr{+x}, +t}:
      md.if(Nat, U32.is_eq(x, c), u => md.only(t, c, 1n+n), u => md.if(Nat, U32.is_eq(x, 32) || U32.is_eq(x, 9), w => md.only(t, c, n), w => 0n))

# a thematic break: three or more * - or _, nothing else but spaces
def md.is.rule(+s: String) -> Bool:
  Nat.is_ge(md.only(s, 42, 0n), 3n) || Nat.is_ge(md.only(s, 45, 0n), 3n) || Nat.is_ge(md.only(s, 95, 0n), 3n)

# an ATX heading: its level (0: none) and its text
def md.atx.level(r: md.Run) -> Nat:
  match r:
    case md.Run{+n, +rest}:
      Bool.pick(Nat, Nat.is_ge(n, 1n) && Nat.is_le(n, 6n) && (String.is_empty(rest) || U32.is_eq(md.first(rest), 32) || U32.is_eq(md.first(rest), 9)), n, 0n)

def md.atx.close.g(r: md.Run, +s: String) -> String:
  match r:
    case md.Run{+n, +rest}:
      md.if(String, Nat.is_eq(n, 0n), u => s,
        u => md.if(String, String.is_empty(rest), u => "", u => Bool.pick(String, U32.is_eq(md.first(rest), 32) || U32.is_eq(md.first(rest), 9), String.reverse(rest), s)))

def md.atx.close.r(rv: String, +s: String) -> String:
  md.atx.close.g(md.run(rv, 35, 0n), s)

# a closing sequence of #s (after a space, or the whole) dropped
def md.atx.close(+s: String) -> String:
  md.atx.close.r(String.reverse(s), s)

def md.atx.text.r(+r: String) -> String:
  X.tx.strip(md.atx.close(X.tx.strip(r)))

def md.atx.text(r: md.Run) -> String:
  match r:
    case md.Run{n, +rest}:
      md.atx.text.r(rest)

# a fence: its character and length (0: none), and its info string
type md.Fence is Data:
  md.Fence{c: U32, n: Nat, info: String}

def md.fence.r(+c: U32, r: md.Run) -> md.Fence:
  match r:
    case md.Run{+n, +rest}:
      Bool.pick(md.Fence, Nat.is_ge(n, 3n) && Bool.not(U32.is_eq(c, 96) && String.contains(rest, "`")), md.Fence{c, n, X.tx.strip(rest)}, md.Fence{c, 0n, ""})

def md.fence(+s: String) -> md.Fence:
  md.if(md.Fence, U32.is_eq(md.first(s), 96) || U32.is_eq(md.first(s), 126), u => md.fence.r(md.first(s), md.run(s, md.first(s), 0n)), u => md.Fence{0, 0n, ""})

def md.fence.n(f: md.Fence) -> Nat:
  match f:
    case md.Fence{c, n, i}:
      n

# a list marker: none, or bullet/ordered, its character (- + * or . )),
# its number, its width, and the item's text after it
type md.Mark is Data:
  md.NoMark{}
  md.Mark{ordered: Bool, c: U32, start: Nat, width: Nat, rest: String}

# the spaces after the marker: 1 to 4 belong to it, more mean code in the item
def md.mark.sp(+ordered: Bool, +c: U32, +start: Nat, +w: Nat, i: md.Ind) -> md.Mark:
  match i:
    case md.Ind{+k, +r}:
      md.if(md.Mark, md.blank(r), u => md.Mark{ordered, c, start, 1n+w, ""},
        u => Bool.pick(md.Mark, Nat.is_gt(k, 4n), md.Mark{ordered, c, start, 1n+w, md.dedent(1n, String.repeat(" ", k) ++ r)},
          md.Mark{ordered, c, start, Nat.add(w, k), r}))

def md.mark.after(+ordered: Bool, +c: U32, +start: Nat, +w: Nat, +rest: String) -> md.Mark:
  md.if(md.Mark, String.is_empty(rest), u => md.Mark{ordered, c, start, 1n+w, ""},
    u => md.if(md.Mark, U32.is_eq(md.first(rest), 32) || U32.is_eq(md.first(rest), 9),
      u => md.mark.sp(ordered, c, start, w, md.ind(rest)), u => md.NoMark{}))

def md.mark.num(g: md.Got) -> md.Mark:
  match g:
    case md.Got{+ds, +rest}:
      md.if(md.Mark, Bool.not(String.is_empty(ds)) && Nat.is_le(String.length(ds), 9n) && (U32.is_eq(md.first(rest), 46) || U32.is_eq(md.first(rest), 41)),
        u => md.mark.after(True{}, md.first(rest), md.decval(ds, 0n), 1n+String.length(ds), String.drop(rest, 1n)), u => md.NoMark{})

def md.mark(+s: String) -> md.Mark:
  md.if(md.Mark, U32.is_eq(md.first(s), 45) || U32.is_eq(md.first(s), 43) || U32.is_eq(md.first(s), 42),
    u => md.mark.after(False{}, md.first(s), 0n, 1n, String.drop(s, 1n)), u => md.mark.num(md.span(~md.digit, 10n, s)))

def md.mark.ok(m: md.Mark) -> Bool:
  match m:
    case md.NoMark{}:
      False{}
    case md.Mark{o, c, s, w, r}:
      True{}

# a marker that may break into a paragraph: its item is not empty, and an
# ordered one starts at 1
def md.mark.breaks(m: md.Mark) -> Bool:
  match m:
    case md.NoMark{}:
      False{}
    case md.Mark{+o, c, +s, w, +r}:
      Bool.not(md.blank(r)) && (Bool.not(o) || Nat.is_eq(s, 1n))

# HTML blocks: the kind of block a line starts (CommonMark's 1 to 7; 0 none)
def md.block.tags() -> List<&2, String>:
  ["address", "article", "aside", "base", "basefont", "blockquote", "body", "caption", "center", "col", "colgroup", "dd", "details", "dialog",
   "dir", "div", "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form", "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6",
   "head", "header", "hr", "html", "iframe", "legend", "li", "link", "main", "menu", "menuitem", "nav", "noframes", "ol", "optgroup", "option",
   "p", "param", "search", "section", "summary", "table", "tbody", "td", "tfoot", "th", "thead", "title", "tr", "track", "ul"]

def md.tag.end(+s: String) -> Bool:
  String.is_empty(s) || md.white(md.first(s)) || String.starts_with(s, ">") || String.starts_with(s, "/>")

def md.tag.in(ts: List<&2, String>, +s: String) -> Bool:
  match ts:
    case Nil{}:
      False{}
    case Con{+t, r}:
      (String.starts_with(s, t) && md.tag.end(String.drop(s, String.length(t)))) || md.tag.in(r, s)

def md.html.seven(+s: String) -> Bool:
  (md.letter(md.first(String.drop(s, 1n))) || (String.starts_with(s, "</") && md.letter(md.first(String.drop(s, 2n)))))
    && String.ends_with(X.tx.strip(s), ">") && Nat.is_eq(md.count(s, 60, 0n), 1n)

def md.html.kind(+low: String, +para: Bool) -> Nat:
  md.if(Nat, Bool.not(String.starts_with(low, "<")), u => 0n,
  u => md.if(Nat, md.tag.in(["<script", "<pre", "<style", "<textarea"], low), u => 1n,
  u => md.if(Nat, String.starts_with(low, "<!--"), u => 2n,
  u => md.if(Nat, String.starts_with(low, "<?"), u => 3n,
  u => md.if(Nat, String.starts_with(low, "<![cdata["), u => 5n,
  u => md.if(Nat, String.starts_with(low, "<!") && md.letter(md.first(String.drop(low, 2n))), u => 4n,
  u => md.if(Nat, md.tag.in(md.block.tags(), String.drop(low, Bool.pick(Nat, String.starts_with(low, "</"), 2n, 1n))), u => 6n,
  u => Bool.pick(Nat, Bool.not(para) && md.html.seven(low), 7n, 0n))))))))

def md.html.ends(+kind: Nat, +low: String) -> Bool:
  Bool.pick(Bool, Nat.is_eq(kind, 1n), String.contains(low, "</script>") || String.contains(low, "</pre>") || String.contains(low, "</style>") || String.contains(low, "</textarea>"),
    Bool.pick(Bool, Nat.is_eq(kind, 2n), String.contains(low, "-->"), Bool.pick(Bool, Nat.is_eq(kind, 3n), String.contains(low, "?>"),
      Bool.pick(Bool, Nat.is_eq(kind, 4n), String.contains(low, ">"), Bool.pick(Bool, Nat.is_eq(kind, 5n), String.contains(low, "]]>"), False{})))))

# a line that ends a paragraph and starts a block of its own
def md.breaks.s(+s: String) -> Bool:
  Nat.is_ge(md.fence.n(md.fence(s)), 3n) || Nat.is_gt(md.atx.level(md.run(s, 35, 0n)), 0n) || md.is.rule(s) || String.starts_with(s, ">")
    || md.mark.breaks(md.mark(s)) || Nat.is_gt(md.html.kind(String.to_lower(s), True{}), 0n)

def md.breaks(+l: String) -> Bool:
  Nat.is_le(md.cols(l), 3n) && md.breaks.s(md.unind(l))

# Tables (GitHub's): cells cut at "|" (not "\|"), the outer ones' pipes dropped
def md.cells.go(+fuel: Nat, s: String, +acc: String) -> List<&2, String>:
  match fuel s:
    case 0n x:
      [String.reverse(acc)]
    case 1n+f SNil{}:
      [String.reverse(acc)]
    case 1n+f SCon{Chr{92}, SCon{Chr{124}, t}}:
      md.cells.go(f, t, SCon{Chr{124}, acc})
    case 1n+f SCon{Chr{124}, t}:
      String.reverse(acc) <> md.cells.go(f, t, "")
    case 1n+f SCon{h, t}:
      md.cells.go(f, t, SCon{h, acc})

def md.cells.trim(cs: List<&2, String>) -> List<&2, String>:
  match cs:
    case Nil{}:
      []
    case Con{c, t}:
      X.tx.strip(c) <> md.cells.trim(t)

def md.cells.of(+s: String) -> List<&2, String>:
  md.cells.trim(md.cells.go(1n+String.length(s), s, ""))

def md.cells.inner.end(+s: String) -> String:
  Bool.pick(String, String.ends_with(s, "|") && Bool.not(String.ends_with(s, "\\|")), String.take(s, Nat.sub(String.length(s), 1n)), s)

def md.cells.inner(+s: String) -> String:
  md.cells.inner.end(Bool.pick(String, String.starts_with(s, "|"), String.drop(s, 1n), s))

def md.cells(+l: String) -> List<&2, String>:
  md.cells.of(md.cells.inner(X.tx.strip(l)))

def md.dash.c(+c: U32) -> Bool:
  U32.is_eq(c, 45)

def md.al.mk(l: Bool, r: Bool) -> md.Al:
  match l r:
    case True{} True{}:
      md.ACenter{}
    case True{} False{}:
      md.ALeft{}
    case False{} True{}:
      md.ARight{}
    case False{} False{}:
      md.ANone{}

def md.al.mid(l: Bool, r: Bool, g: md.Got) -> Maybe<&2, md.Al>:
  match g:
    case md.Got{+ds, +rest}:
      md.if(Maybe<&2, md.Al>, String.is_empty(ds) || Bool.not(String.eq(rest, "") || String.eq(rest, ":")), u => None{},
        u => Some{md.al.mk(l, r)})

# a delimiter cell's alignment, if it is one (:?-+:?)
def md.al.of(+c: String) -> Maybe<&2, md.Al>:
  md.al.mid(String.starts_with(c, ":"), String.ends_with(c, ":") && Nat.is_gt(String.length(c), 1n), md.span(~md.dash.c, 1000n, String.drop(c, Bool.pick(Nat, String.starts_with(c, ":"), 1n, 0n))))

def md.aligns.cons(a: Maybe<&2, md.Al>, r: Maybe<&2, List<&2, md.Al>>) -> Maybe<&2, List<&2, md.Al>>:
  match a r:
    case Some{x} Some{xs}:
      Some{x <> xs}
    case x y:
      None{}

def md.aligns(cs: List<&2, String>) -> Maybe<&2, List<&2, md.Al>>:
  match cs:
    case Nil{}:
      Some{[]}
    case Con{+c, t}:
      md.aligns.cons(md.al.of(c), md.aligns(t))

# Taking lines
# ------------

type md.Cut is Data:
  md.Cut{taken: List<&2, String>, rest: List<&2, String>}

def md.cut.cons(+l: String, c: md.Cut) -> md.Cut:
  match c:
    case md.Cut{a, r}:
      md.Cut{l <> a, r}

def md.take.code(ls: List<&2, String>) -> md.Cut:
  match ls:
    case Nil{}:
      md.Cut{[], []}
    case Con{+l, +t}:
      md.if(md.Cut, md.blank(l) || Nat.is_ge(md.cols(l), 4n), u => md.cut.cons(md.dedent(4n, l), md.take.code(t)), u => md.Cut{[], l <> t})

def md.fence.shut(+c: U32, +n: Nat, f: md.Fence) -> Bool:
  match f:
    case md.Fence{+c2, +n2, +i}:
      U32.is_eq(c2, c) && Nat.is_ge(n2, n) && String.is_empty(i)

def md.fence.closes(+c: U32, +n: Nat, +l: String) -> Bool:
  Nat.is_le(md.cols(l), 3n) && md.fence.shut(c, n, md.fence(md.unind(l)))

# a fenced block's lines (k: its fence's indentation, taken off each), the
# closing fence dropped
def md.take.fence(ls: List<&2, String>, +c: U32, +n: Nat, +k: Nat) -> md.Cut:
  match ls:
    case Nil{}:
      md.Cut{[], []}
    case Con{+l, +t}:
      md.if(md.Cut, md.fence.closes(c, n, l), u => md.Cut{[], t}, u => md.cut.cons(md.dedent(k, l), md.take.fence(t, c, n, k)))

def md.quote.sp(+s: String) -> String:
  Bool.pick(String, String.starts_with(s, " "), String.drop(s, 1n), Bool.pick(String, String.starts_with(s, "\t"), "  " ++ String.drop(s, 1n), s))

def md.quote.strip(+s: String) -> String:
  md.quote.sp(String.drop(s, 1n))

def md.is.quote(+l: String) -> Bool:
  Nat.is_le(md.cols(l), 3n) && String.starts_with(md.unind(l), ">")

# a block quote's lines, its ">" taken off, and the lazy lines that go on
# its paragraph
def md.take.quote(ls: List<&2, String>, +lazy: Bool) -> md.Cut:
  match ls:
    case Nil{}:
      md.Cut{[], []}
    case Con{+l, +t}:
      md.if(md.Cut, md.is.quote(l), u => md.cut.cons(md.quote.strip(md.unind(l)), md.take.quote(t, Bool.not(md.blank(md.quote.strip(md.unind(l)))))),
        u => md.if(md.Cut, lazy && Bool.not(md.blank(l)) && Bool.not(md.breaks(l)) && Bool.not(md.mark.ok(md.mark(md.unind(l)))),
          u => md.cut.cons(l, md.take.quote(t, True{})), u => md.Cut{[], l <> t}))

# a list item's lines after its first (w: the column its text starts at)
def md.take.item(ls: List<&2, String>, +w: Nat, +lazy: Bool) -> md.Cut:
  match ls:
    case Nil{}:
      md.Cut{[], []}
    case Con{+l, +t}:
      md.if(md.Cut, md.blank(l), u => md.cut.cons("", md.take.item(t, w, False{})),
        u => md.if(md.Cut, Nat.is_ge(md.cols(l), w), u => md.cut.cons(md.dedent(w, l), md.take.item(t, w, True{})),
          u => md.if(md.Cut, lazy && Bool.not(md.breaks(l)) && Bool.not(md.mark.ok(md.mark(md.unind(l)))),
            u => md.cut.cons(md.unind(l), md.take.item(t, w, True{})), u => md.Cut{[], l <> t})))

def md.take.rows(ls: List<&2, String>) -> md.Cut:
  match ls:
    case Nil{}:
      md.Cut{[], []}
    case Con{+l, +t}:
      md.if(md.Cut, md.blank(l) || md.breaks(l), u => md.Cut{[], l <> t}, u => md.cut.cons(l, md.take.rows(t)))

def md.take.html(ls: List<&2, String>, +kind: Nat) -> md.Cut:
  match ls:
    case Nil{}:
      md.Cut{[], []}
    case Con{+l, +t}:
      md.if(md.Cut, Nat.is_le(kind, 5n),
        u => md.if(md.Cut, md.html.ends(kind, String.to_lower(l)), w => md.Cut{[l], t}, w => md.cut.cons(l, md.take.html(t, kind))),
        u => md.if(md.Cut, md.blank(l), w => md.Cut{[], l <> t}, w => md.cut.cons(l, md.take.html(t, kind))))

# a paragraph's lines, and a setext heading's level if a line of = or -
# ends it (0: none)
type md.PCut is Data:
  md.PCut{taken: List<&2, String>, level: Nat, rest: List<&2, String>}

def md.pcut.cons(+l: String, c: md.PCut) -> md.PCut:
  match c:
    case md.PCut{a, n, r}:
      md.PCut{l <> a, n, r}

def md.setext.g(r: md.Run) -> Bool:
  match r:
    case md.Run{+n, +rest}:
      Nat.is_gt(n, 0n) && md.blank(rest)

def md.setext.s(+s: String, +c: U32) -> Bool:
  md.setext.g(md.run(s, c, 0n))

def md.setext(+l: String, +c: U32) -> Bool:
  Nat.is_le(md.cols(l), 3n) && md.setext.s(md.unind(l), c)

def md.table.al.ok(m: Maybe<&2, List<&2, md.Al>>, +l: String) -> Bool:
  match m:
    case Some{+als}:
      Nat.is_eq(List.length(&2, md.Al, als), List.length(&2, String, md.cells(l)))
    case None{}:
      False{}

# whether l and the line after it start a table (l its header)
def md.table.next(+l: String, t: List<&2, String>) -> Bool:
  match t:
    case Con{+d, r}:
      String.contains(l, "|") && String.contains(d, "-") && md.table.al.ok(md.aligns(md.cells(d)), l)
    case Nil{}:
      False{}

def md.take.para(ls: List<&2, String>) -> md.PCut:
  match ls:
    case Nil{}:
      md.PCut{[], 0n, []}
    case Con{+l, +t}:
      md.if(md.PCut, md.setext(l, 61), u => md.PCut{[], 1n, t},
        u => md.if(md.PCut, md.setext(l, 45), u => md.PCut{[], 2n, t},
          u => md.if(md.PCut, md.blank(l) || md.breaks(l) || md.table.next(l, t), u => md.PCut{[], 0n, l <> t}, u => md.pcut.cons(l, md.take.para(t)))))

# Lists
# -----

type md.IL is Data:
  md.IL{task: Nat, lines: List<&2, String>}

type md.LCut is Data:
  md.LCut{items: List<&2, md.IL>, spaced: Bool, rest: List<&2, String>}

def md.same.mark(+o: Bool, +c: U32, m: md.Mark) -> Bool:
  match m:
    case md.NoMark{}:
      False{}
    case md.Mark{+o2, +c2, s, w, r}:
      ((o && o2) || (Bool.not(o) && Bool.not(o2))) && U32.is_eq(c, c2)

# whether a line starts an item of the same list
def md.same.item(+o: Bool, +c: U32, +l: String) -> Bool:
  Nat.is_le(md.cols(l), 3n) && Bool.not(md.is.rule(md.unind(l))) && md.same.mark(o, c, md.mark(md.unind(l)))

# a task item's box: "[ ] " (1) or "[x] " (2)
def md.task(+s: String) -> Nat:
  Bool.pick(Nat, String.starts_with(s, "[ ] ") || String.eq(s, "[ ]"), 1n,
    Bool.pick(Nat, String.starts_with(s, "[x] ") || String.starts_with(s, "[X] ") || String.eq(s, "[x]") || String.eq(s, "[X]"), 2n, 0n))

def md.task.rest(+k: Nat, +s: String) -> String:
  Bool.pick(String, Nat.is_eq(k, 0n), s, String.drop(s, 4n))

def md.lcut.cons(it: md.IL, +sep: Bool, c: md.LCut) -> md.LCut:
  match c:
    case md.LCut{+items, +sp, r}:
      md.LCut{it <> items, sp || sep, r}

# an item's lines; its trailing blank lines go back to what follows it
def md.list.lines(+first: String, c: md.Cut, more: List<&2, String> -> md.LCut) -> md.LCut:
  match c:
    case md.Cut{+ls, r}:
      md.lcut.cons(md.IL{md.task(first), md.task.rest(md.task(first), first) <> md.trim.blank(ls)}, False{},
        more(List.append(&2, String, List.drop(&2, String, ls, List.length(&2, String, md.trim.blank(ls))), r)))

def md.list.item(m: md.Mark, +k: Nat, +t: List<&2, String>, more: List<&2, String> -> md.LCut) -> md.LCut:
  match m:
    case md.NoMark{}:
      md.LCut{[], False{}, t}
    case md.Mark{o, c, s, +w, +first}:
      md.list.lines(first, md.take.item(t, Nat.add(k, w), Bool.not(md.blank(first))), more)

def md.next.line(ls: List<&2, String>) -> String:
  match ls:
    case Nil{}:
      ""
    case Con{+l, t}:
      md.if(String, md.blank(l), u => md.next.line(t), u => l)

def md.lcut.spaced(c: md.LCut) -> md.LCut:
  match c:
    case md.LCut{items, sp, r}:
      md.LCut{items, True{}, r}

# a list's items, each with its lines (the marker's width taken off), and
# whether blank lines part them (a blank line, then an item of the list:
# the list goes on, spaced)
def md.take.list(+fuel: Nat, ls: List<&2, String>, +o: Bool, +c: U32) -> md.LCut:
  match fuel ls:
    case 0n x:
      md.LCut{[], False{}, x}
    case 1n+f Nil{}:
      md.LCut{[], False{}, []}
    case 1n+f Con{+l, +t}:
      md.if(md.LCut, md.blank(l),
        u => md.if(md.LCut, md.same.item(o, c, md.next.line(t)), w => md.lcut.spaced(md.take.list(f, t, o, c)), w => md.LCut{[], False{}, l <> t}),
        u => md.if(md.LCut, md.same.item(o, c, l), w => md.list.item(md.mark(md.unind(l)), md.cols(l), t, r => md.take.list(f, r, o, c)),
          w => md.LCut{[], False{}, l <> t}))

# Blocks read
# -----------

# What the lines at the reader's place begin: a blank line, a block whole, a
# block quote or a list (their lines still to read), an item, or the end.
type md.BS is Data:
  md.BNone{rest: List<&2, String>}
  md.BLeaf{b: md.B, rest: List<&2, String>}
  md.BQuote{inner: List<&2, String>, rest: List<&2, String>}
  md.BList{ordered: Bool, start: Nat, spaced: Bool, items: List<&2, md.IL>, rest: List<&2, String>}
  md.BItem{task: Nat, lines: List<&2, String>, more: List<&2, md.IL>}
  md.BEnd{}

def md.first.word(ws: List<&2, String>) -> String:
  match ws:
    case Nil{}:
      ""
    case Con{w, t}:
      w

def md.code.class(+info: String) -> String:
  md.first.word(X.tx.words(info))

def md.b.fence.cut(+info: String, c: md.Cut) -> md.BS:
  match c:
    case md.Cut{ls, r}:
      md.BLeaf{md.Code{md.unesc(info), md.body(ls)}, r}

def md.b.fence(f: md.Fence, +k: Nat, +t: List<&2, String>) -> md.BS:
  match f:
    case md.Fence{+c, +n, +info}:
      md.b.fence.cut(info, md.take.fence(t, c, n, k))

def md.b.code(c: md.Cut) -> md.BS:
  match c:
    case md.Cut{ls, r}:
      md.BLeaf{md.Code{"", md.body(md.trim.blank(ls))}, r}

def md.b.quote(c: md.Cut) -> md.BS:
  match c:
    case md.Cut{ls, r}:
      md.BQuote{ls, r}

def md.b.html(c: md.Cut) -> md.BS:
  match c:
    case md.Cut{ls, r}:
      md.BLeaf{md.Html{md.body(ls)}, r}

def md.b.list.cut(+o: Bool, +s: Nat, c: md.LCut) -> md.BS:
  match c:
    case md.LCut{items, sp, r}:
      md.BList{o, s, sp, items, r}

def md.b.list(m: md.Mark, +ls: List<&2, String>) -> md.BS:
  match m:
    case md.NoMark{}:
      md.BNone{ls}
    case md.Mark{+o, +c, +s, w, r}:
      md.b.list.cut(o, s, md.take.list(1n+List.length(&2, String, ls), ls, o, c))

def md.para.text(ls: List<&2, String>) -> String:
  X.tx.strip.end(md.join(X.tx.strip.lines(ls)))

def md.b.para(+l: String, c: md.PCut) -> md.BS:
  match c:
    case md.PCut{+ls, +lv, +r}:
      Bool.pick(md.BS, Nat.is_eq(lv, 0n), md.BLeaf{md.Para{md.inline(md.para.text(l <> ls))}, r},
        md.BLeaf{md.Head{lv, md.inline(md.para.text(l <> ls))}, r})

# a table: its header (l), the delimiter row's alignments, its rows (a
# row's cells fit to the header's: missing ones empty, extra ones dropped)
def md.row.fit(als: List<&2, md.Al>, cs: List<&2, String>) -> List<&2, List<&2, md.I>>:
  match als cs:
    case Nil{} x:
      []
    case Con{a, at} Nil{}:
      [] <> md.row.fit(at, [])
    case Con{a, at} Con{+c, ct}:
      md.inline(c) <> md.row.fit(at, ct)

def md.rows(ls: List<&2, String>, +als: List<&2, md.Al>) -> List<&2, List<&2, List<&2, md.I>>>:
  match ls:
    case Nil{}:
      []
    case Con{+l, t}:
      md.row.fit(als, md.cells(l)) <> md.rows(t, als)

def md.b.table.cut(+als: List<&2, md.Al>, +head: String, c: md.Cut) -> md.BS:
  match c:
    case md.Cut{ls, r}:
      md.BLeaf{md.Table{als, md.row.fit(als, md.cells(head)), md.rows(ls, als)}, r}

def md.b.table.al(m: Maybe<&2, List<&2, md.Al>>, +l: String, +t: List<&2, String>) -> Maybe<&2, md.BS>:
  match m:
    case Some{+als}:
      md.if(Maybe<&2, md.BS>, Nat.is_eq(List.length(&2, md.Al, als), List.length(&2, String, md.cells(l))) && String.contains(l, "|"),
        u => Some{md.b.table.cut(als, l, md.take.rows(List.drop(&2, String, t, 1n)))}, u => None{})
    case None{}:
      None{}

def md.b.table(+l: String, +t: List<&2, String>) -> Maybe<&2, md.BS>:
  match t:
    case Nil{}:
      None{}
    case Con{+d, r}:
      md.if(Maybe<&2, md.BS>, String.contains(d, "-") && Bool.not(md.blank(d)), u => md.b.table.al(md.aligns(md.cells(d)), l, t), u => None{})

def md.b.table.or(m: Maybe<&2, md.BS>, +l: String, +t: List<&2, String>) -> md.BS:
  match m:
    case Some{bs}:
      bs
    case None{}:
      md.b.para(l, md.take.para(t))

def md.bstart.s(+l: String, +s: String, +t: List<&2, String>) -> md.BS:
  md.if(md.BS, Nat.is_ge(md.fence.n(md.fence(s)), 3n), u => md.b.fence(md.fence(s), md.cols(l), t),
  u => md.if(md.BS, Nat.is_gt(md.atx.level(md.run(s, 35, 0n)), 0n), u => md.BLeaf{md.Head{md.atx.level(md.run(s, 35, 0n)), md.inline(md.atx.text(md.run(s, 35, 0n)))}, t},
  u => md.if(md.BS, md.is.rule(s), u => md.BLeaf{md.Rule{}, t},
  u => md.if(md.BS, String.starts_with(s, ">"), u => md.b.quote(md.take.quote(l <> t, True{})),
  u => md.if(md.BS, md.mark.ok(md.mark(s)), u => md.b.list(md.mark(s), l <> t),
  u => md.if(md.BS, Nat.is_gt(md.html.kind(String.to_lower(s), False{}), 0n), u => md.b.html(md.take.html(l <> t, md.html.kind(String.to_lower(s), False{}))),
  u => md.b.table.or(md.b.table(l, t), l, t)))))))

def md.bstart(+l: String, +t: List<&2, String>) -> md.BS:
  md.if(md.BS, md.blank(l), u => md.BNone{t},
    u => md.if(md.BS, Nat.is_ge(md.cols(l), 4n), u => md.b.code(md.take.code(l <> t)), u => md.bstart.s(l, md.unind(l), t)))

def md.bnext(ls: List<&2, String>) -> md.BS:
  match ls:
    case Nil{}:
      md.BEnd{}
    case Con{+l, +t}:
      md.bstart(l, t)

def md.items.next(its: List<&2, md.IL>) -> md.BS:
  match its:
    case Nil{}:
      md.BEnd{}
    case Con{md.IL{k, ls}, t}:
      md.BItem{k, ls, t}

# The reader of blocks (fuel: a bound on its steps, each of which reads a
# line or goes into a container's fewer lines)
def md.blocks(+fuel: Nat, st: md.BS) -> List<&2, md.B>:
  match fuel st:
    case 0n x:
      []
    case 1n+f md.BEnd{}:
      []
    case 1n+f md.BNone{r}:
      md.Gap{} <> md.blocks(f, md.bnext(r))
    case 1n+f md.BLeaf{b, r}:
      b <> md.blocks(f, md.bnext(r))
    case 1n+f md.BQuote{inner, r}:
      md.Quote{md.blocks(f, md.bnext(inner))} <> md.blocks(f, md.bnext(r))
    case 1n+f md.BList{o, s, sp, items, r}:
      md.List{o, s, sp, md.blocks(f, md.items.next(items))} <> md.blocks(f, md.bnext(r))
    case 1n+f md.BItem{k, ls, more}:
      md.Item{k, md.blocks(f, md.bnext(ls))} <> md.blocks(f, md.items.next(more))

def md.cr.drop(+l: String) -> String:
  Bool.pick(String, String.ends_with(l, "\r"), String.take(l, Nat.sub(String.length(l), 1n)), l)

def md.lines(ls: List<&2, String>) -> List<&2, String>:
  match ls:
    case Nil{}:
      []
    case Con{+l, t}:
      md.cr.drop(l) <> md.lines(t)

# a text read as blocks
def md.parse(s: String) -> List<&2, md.B>:
  md.blocks(1000000n, md.bnext(md.lines(String.split(s, '\n'))))

# Writing blocks
# --------------

# whether two of an item's blocks have a blank line between them
def md.gapped(ks: List<&2, md.B>, +seen: Bool, +gap: Bool) -> Bool:
  match ks:
    case Nil{}:
      False{}
    case Con{md.Gap{}, t}:
      md.gapped(t, seen, seen)
    case Con{x, t}:
      gap || md.gapped(t, True{}, False{})

def md.loose(items: List<&2, md.B>) -> Bool:
  match items:
    case Nil{}:
      False{}
    case Con{md.Item{k, +ks}, t}:
      md.gapped(ks, False{}, False{}) || md.loose(t)
    case Con{x, t}:
      md.loose(t)

def md.cr(+fresh: Bool) -> String:
  Bool.pick(String, fresh, "", "\n")

def md.list.open(+o: Bool, +s: Nat) -> String:
  Bool.pick(String, o, Bool.pick(String, Nat.is_eq(s, 1n), "<ol>\n", "<ol start=\"" ++ Nat.show(s) ++ "\">\n"), "<ul>\n")

def md.box(+k: Nat) -> String:
  Bool.pick(String, Nat.is_eq(k, 1n), "<input type=\"checkbox\" disabled=\"\" /> ",
    Bool.pick(String, Nat.is_eq(k, 2n), "<input type=\"checkbox\" checked=\"\" disabled=\"\" /> ", ""))

def md.class(+info: String) -> String:
  Bool.pick(String, String.is_empty(md.code.class(info)), "", " class=\"language-" ++ md.esc(md.code.class(info), "\""))

def md.al.attr(a: md.Al) -> String:
  match a:
    case md.ANone{}:
      ""
    case md.ALeft{}:
      " align=\"left\""
    case md.ACenter{}:
      " align=\"center\""
    case md.ARight{}:
      " align=\"right\""

def md.tds(+tag: String, als: List<&2, md.Al>, cs: List<&2, List<&2, md.I>>, +hard: Bool) -> String:
  match als cs:
    case Con{a, at} Con{c, ct}:
      "<" ++ tag ++ md.al.attr(a) ++ ">" ++ X.tx.strip(md.inl(c, hard, "")) ++ "</" ++ tag ++ ">\n" ++ md.tds(tag, at, ct, hard)
    case x y:
      ""

def md.tr(+tag: String, +als: List<&2, md.Al>, cs: List<&2, List<&2, md.I>>, +hard: Bool) -> String:
  "<tr>\n" ++ md.tds(tag, als, cs, hard) ++ "</tr>\n"

def md.trs(+als: List<&2, md.Al>, rows: List<&2, List<&2, List<&2, md.I>>>, +hard: Bool) -> String:
  match rows:
    case Nil{}:
      ""
    case Con{r, t}:
      md.tr("td", als, r, hard) ++ md.trs(als, t, hard)

# a table as Render.hs writes one (cmark-gfm's own form)
def md.table(+als: List<&2, md.Al>, head: List<&2, List<&2, md.I>>, +rows: List<&2, List<&2, List<&2, md.I>>>, +hard: Bool) -> String:
  "<table>\n<thead>\n" ++ md.tr("th", als, head, hard) ++ "</thead>\n"
    ++ Bool.pick(String, List.is_empty(&2, List<&2, List<&2, md.I>>, rows), "", "<tbody>\n" ++ md.trs(als, rows, hard) ++ "</tbody>\n") ++ "</table>\n"

def md.raw.nl(+h: String) -> String:
  Bool.pick(String, String.ends_with(h, "\n"), h, h ++ "\n")

# The blocks xs as HTML, before out, as cmark writes them (tight: in a tight
# list's item, a paragraph is its inlines alone; fresh: what came before
# ends a line)
def md.blk(xs: List<&2, md.B>, +tight: Bool, +hard: Bool, +fresh: Bool, +out: String) -> String:
  match xs:
    case Nil{}:
      out
    case Con{md.Gap{}, t}:
      md.blk(t, tight, hard, fresh, out)
    case Con{md.Para{+ks}, +t}:
      md.if(String, tight, u => md.inl(ks, hard, md.blk(t, tight, hard, False{}, out)),
        u => md.cr(fresh) ++ "<p>" ++ md.inl(ks, hard, "</p>\n" ++ md.blk(t, tight, hard, True{}, out)))
    case Con{md.Head{+n, ks}, t}:
      md.cr(fresh) ++ "<h" ++ Nat.show(n) ++ ">" ++ md.inl(ks, hard, "</h" ++ Nat.show(n) ++ ">\n" ++ md.blk(t, tight, hard, True{}, out))
    case Con{md.Code{+info, body}, t}:
      md.cr(fresh) ++ "<pre><code" ++ md.class(info) ++ ">" ++ md.esc(body, "</code></pre>\n" ++ md.blk(t, tight, hard, True{}, out))
    case Con{md.Html{h}, t}:
      md.cr(fresh) ++ "<pre><code>" ++ md.esc(h, "</code></pre>\n" ++ md.blk(t, tight, hard, True{}, out))
    case Con{md.Raw{h}, t}:
      md.cr(fresh) ++ md.raw.nl(h) ++ md.blk(t, tight, hard, True{}, out)
    case Con{md.Quote{ks}, t}:
      md.cr(fresh) ++ "<blockquote>\n" ++ md.blk(ks, False{}, hard, True{}, "</blockquote>\n" ++ md.blk(t, tight, hard, True{}, out))
    case Con{md.List{+o, +s, +sp, +items}, t}:
      md.cr(fresh) ++ md.list.open(o, s) ++ md.blk(items, Bool.not(sp) && Bool.not(md.loose(items)), hard, True{},
        Bool.pick(String, o, "</ol>\n", "</ul>\n") ++ md.blk(t, tight, hard, True{}, out))
    case Con{md.Item{+k, ks}, t}:
      "<li>" ++ md.box(k) ++ md.blk(ks, tight, hard, False{}, "</li>\n" ++ md.blk(t, tight, hard, True{}, out))
    case Con{md.Rule{}, t}:
      md.cr(fresh) ++ "<hr />\n" ++ md.blk(t, tight, hard, True{}, out)
    case Con{md.Table{als, head, rows}, t}:
      md.cr(fresh) ++ md.table(als, head, rows, hard) ++ md.blk(t, tight, hard, True{}, out)

# blocks as HTML (hard: soft breaks as <br />)
def md.html(bs: List<&2, md.B>, +hard: Bool) -> String:
  md.blk(bs, False{}, hard, True{}, "")
