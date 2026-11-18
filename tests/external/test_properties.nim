import std/[unittest, strutils]
import propcheck
import nim_url_resolve

const pathAlphabet = "ab./"
const refAlphabet = "ab./?#:;"

proc hasDotSegment(path: string): bool =
  for seg in path.split('/'):
    if seg == "." or seg == "..": return true
  false

suite "URLR-04 removeDotSegments (性質)":
  # SPEC: URLR-04
  test "Given 任意の path, When removeDotSegments, Then 段としての . と .. は残らない":
    let outcome = check(stringOf(pathAlphabet, 0, 24), proc(p: string): bool {.raises: [CatchableError].} =
      let o = removeDotSegments(p)
      if hasDotSegment(o): raise newException(CatchableError, p & " -> " & o)
      true)
    checkpoint describe(outcome)
    check outcome.passed

  # SPEC: URLR-05
  test "Given 任意の path, When removeDotSegments を 2 度かける, Then 1 度と同じ":
    let outcome = check(stringOf(pathAlphabet, 0, 24), proc(p: string): bool {.raises: [CatchableError].} =
      let once = removeDotSegments(p)
      removeDotSegments(once) == once)
    checkpoint describe(outcome)
    check outcome.passed

suite "URLR-05 解いた結果 (性質)":
  # SPEC: URLR-05
  test "Given 任意の参照, When 解いた結果をもう一度同じ基底で解く, Then 変わらない":
    let outcome = check(stringOf(refAlphabet, 0, 20), proc(r: string): bool {.raises: [CatchableError].} =
      let first = resolveReference("http://h/b/c/d;p?q", r)
      if not first.isOk: return true      # 参照の scheme が空でない形 (":" で始まらない scheme) は下で見る
      let again = resolveReference("http://h/b/c/d;p?q", first.get)
      again.isOk and again.get == first.get)
    checkpoint describe(outcome)
    check outcome.passed

  # SPEC: URLR-03
  test "Given scheme を持つ任意の参照, When 基底を替える, Then 結果は同じ":
    let outcome = check(stringOf(refAlphabet, 0, 20), proc(tail: string): bool {.raises: [CatchableError].} =
      let r = "x:" & tail
      let a = resolveReference("http://h/b/c", r)
      let b = resolveReference("ftp://other/z?q#f", r)
      a.isOk and b.isOk and a.get == b.get)
    checkpoint describe(outcome)
    check outcome.passed
