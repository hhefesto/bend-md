# The proofs of PROPOSED.bend. Nothing here is trusted: `bend PROOF.bend`
# checks every def, `--verdict` rechecks them with BendTT's kernel.

import Base
import ./Md.bend as M
import ./PROPOSED.bend as Proposed

# One character escaped, before r: as inert as r. Its four tests are named
# (a for &, b for <, x for >, d for "), and each case computed.
def esc.char(+c: U32, a: Bool, b: Bool, x: Bool, d: Bool, +ea: {a == U32.is_eq(c, 38) : Bool}, +eb: {b == U32.is_eq(c, 60) : Bool},
  +ex: {x == U32.is_eq(c, 62) : Bool}, +ed: {d == U32.is_eq(c, 34) : Bool}, +r: String) ->
  {Proposed.inert(M.md.esc.at(Bool.not(U32.is_eq(c, 38) || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}:
  match a b x d:
    case False{} False{} False{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Bool.and(Bool.not(_ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), Proposed.inert(r)) == Proposed.inert(r) : Bool}
      %ex : {Bool.and(Bool.not(False{} || _ || U32.is_eq(c, 34)), Proposed.inert(r)) == Proposed.inert(r) : Bool}
      %ed : {Bool.and(Bool.not(False{} || False{} || _), Proposed.inert(r)) == Proposed.inert(r) : Bool}
      {==}
    case False{} False{} False{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(String.append(M.md.esc.pick(False{}, _, U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(String.append(M.md.esc.pick(False{}, False{}, _, U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(String.append(M.md.esc.pick(False{}, False{}, False{}, _, c), r)) == Proposed.inert(r) : Bool}
      {==}
    case False{} False{} True{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(String.append(M.md.esc.pick(False{}, _, U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(String.append(M.md.esc.pick(False{}, False{}, _, U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case False{} False{} True{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || False{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(String.append(M.md.esc.pick(False{}, _, U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(String.append(M.md.esc.pick(False{}, False{}, _, U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case False{} True{} False{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(String.append(M.md.esc.pick(False{}, _, U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case False{} True{} False{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(String.append(M.md.esc.pick(False{}, _, U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case False{} True{} True{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(String.append(M.md.esc.pick(False{}, _, U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case False{} True{} True{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(False{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(False{} || True{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(String.append(M.md.esc.pick(False{}, _, U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} False{} False{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} False{} False{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} False{} True{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} False{} True{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || False{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} True{} False{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} True{} False{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || False{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} True{} True{} False{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}
    case True{} True{} True{} True{}:
      %ea : {Proposed.inert(M.md.esc.at(Bool.not(_ || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %eb : {Proposed.inert(M.md.esc.at(Bool.not(True{} || _ || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ex : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || _ || U32.is_eq(c, 34)), c, r)) == Proposed.inert(r) : Bool}
      %ed : {Proposed.inert(M.md.esc.at(Bool.not(True{} || True{} || True{} || _), c, r)) == Proposed.inert(r) : Bool}
      %ea : {Proposed.inert(String.append(M.md.esc.pick(_, U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), c), r)) == Proposed.inert(r) : Bool}
      {==}

def Proposed.esc_inert(s, out):
  match s:
    case SNil{}:
      {==}
    case SCon{Chr{+c}, +t}:
      Equal.trans(Bool, Proposed.inert(M.md.esc.at(Bool.not(U32.is_eq(c, 38) || U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), c, M.md.esc(t, out))),
        Proposed.inert(M.md.esc(t, out)), Proposed.inert(out),
        esc.char(c, U32.is_eq(c, 38), U32.is_eq(c, 60), U32.is_eq(c, 62), U32.is_eq(c, 34), {==}, {==}, {==}, {==}, M.md.esc(t, out)),
        Proposed.esc_inert(t, out))
