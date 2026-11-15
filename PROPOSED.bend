# Md's laws, proposed (for the human to move into a LAWS.bend, reword or
# drop): PROOF.bend proves them.

import Base
import ./Md.bend as M

# A text is inert when none of its characters is markup: no <, > or ".
def inert(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{Chr{+c}, t}:
      Bool.and(Bool.not(U32.is_eq(c, 60) || U32.is_eq(c, 62) || U32.is_eq(c, 34)), inert(t))

# Escaped text is inert: whatever a message holds, what md.esc writes of it
# opens no tag and closes no attribute (written before out, it is as inert
# as out). So text shown as text never becomes markup it did not mean.
law esc_inert:
  for s: String
  for +out: String
  {inert(M.md.esc(s, out)) == inert(out) : Bool}
