import std/[unittest, strutils]
import nim_url_resolve

proc resolved(base, reference: string): string =
  let r = resolveReference(base, reference)
  doAssert r.isOk, r.error
  r.get

suite "URLR-01 RFC 3986 §5.4 の例":
  const base = "http://a/b/c/d;p?q"

  # SPEC: URLR-01
  test "Given RFC 3986 §5.4.1 の通常の例, When resolveReference, Then 規格の結果":
    const cases = [
      ("g:h", "g:h"), ("g", "http://a/b/c/g"), ("./g", "http://a/b/c/g"), ("g/", "http://a/b/c/g/"),
      ("/g", "http://a/g"), ("//g", "http://g"), ("?y", "http://a/b/c/d;p?y"),
      ("g?y", "http://a/b/c/g?y"), ("#s", "http://a/b/c/d;p?q#s"), ("g#s", "http://a/b/c/g#s"),
      ("g?y#s", "http://a/b/c/g?y#s"), (";x", "http://a/b/c/;x"), ("g;x", "http://a/b/c/g;x"),
      ("g;x?y#s", "http://a/b/c/g;x?y#s"), ("", "http://a/b/c/d;p?q"), (".", "http://a/b/c/"),
      ("./", "http://a/b/c/"), ("..", "http://a/b/"), ("../", "http://a/b/"), ("../g", "http://a/b/g"),
      ("../..", "http://a/"), ("../../", "http://a/"), ("../../g", "http://a/g")]
    for (reference, expected) in cases:
      checkpoint reference
      check resolved(base, reference) == expected

  # SPEC: URLR-01
  test "Given RFC 3986 §5.4.2 の異常の例, When resolveReference, Then 規格の結果 (厳密な読み)":
    const cases = [
      ("../../../g", "http://a/g"), ("../../../../g", "http://a/g"), ("/./g", "http://a/g"),
      ("/../g", "http://a/g"), ("g.", "http://a/b/c/g."), (".g", "http://a/b/c/.g"),
      ("g..", "http://a/b/c/g.."), ("..g", "http://a/b/c/..g"), ("./../g", "http://a/b/g"),
      ("./g/.", "http://a/b/c/g/"), ("g/./h", "http://a/b/c/g/h"), ("g/../h", "http://a/b/c/h"),
      ("g;x=1/./y", "http://a/b/c/g;x=1/y"), ("g;x=1/../y", "http://a/b/c/y"),
      ("g?y/./x", "http://a/b/c/g?y/./x"), ("g?y/../x", "http://a/b/c/g?y/../x"),
      ("g#s/./x", "http://a/b/c/g#s/./x"), ("g#s/../x", "http://a/b/c/g#s/../x"),
      ("http:g", "http:g")]
    for (reference, expected) in cases:
      checkpoint reference
      check resolved(base, reference) == expected

  # SPEC: URLR-01
  test "Given 段の途中に .. を含む参照, When resolveReference, Then 段の中身はそのまま":
    check resolved(base, "g../h") == "http://a/b/c/g../h"
    check resolved(base, "a/.../c") == "http://a/b/c/a/.../c"

  # SPEC: URLR-01
  test "Given path の無い基底, When 相対の path か query, Then / を補って merge する (§5.2.3)":
    check resolved("http://a", "b") == "http://a/b"
    check resolved("http://a?q", "?r") == "http://a?r"

  # SPEC: URLR-01
  test "Given path が段 1 つの基底, When 相対の path, Then 最後の / までを残して merge する (§5.2.3)":
    check resolved("http://a/c", "g") == "http://a/g"
    check resolved("http://a/c", "../g") == "http://a/g"

  # SPEC: URLR-01
  test "Given 空の authority の参照, When resolveReference, Then authority は空のまま path の dot segment を除く":
    check resolved("http://a/b", "///../g") == "http:///g"

suite "URLR-02 基底":
  # SPEC: URLR-02
  test "Given scheme の無い基底, When 相対の参照, Then 失敗":
    check not resolveReference("", "g").isOk
    check not resolveReference("/a/b", "g").isOk
    check not resolveReference("//a/b", "g").isOk

  # SPEC: URLR-02
  test "Given scheme の無い基底, When 相対の参照, Then 失敗の理由は基底を示す":
    let r = resolveReference("/a/b", "g")
    check not r.isOk
    check "/a/b" in r.error
    check "no scheme" in r.error

  # SPEC: URLR-02
  test "Given フラグメントのある基底, When 空の参照, Then 基底のフラグメントは捨てる":
    check resolved("http://a/b#f", "") == "http://a/b"

suite "URLR-03 scheme を持つ参照":
  # SPEC: URLR-03
  test "Given scheme を持つ参照, When resolveReference, Then 基底に依らず dot segment だけ除く":
    check resolved("http://a/b/c", "https://x/y/../z/.") == "https://x/z/"
    check resolved("ftp://other/", "https://x/y/../z/.") == "https://x/z/"
    check resolved("", "https://x/y/../z") == "https://x/z"

  # SPEC: URLR-03
  test "Given 大文字の scheme, When resolveReference, Then scheme だけ小文字にする (§6.2.2.1)":
    check resolved("HTTP://A/b/c", "d") == "http://A/b/d"
    check resolved("http://a/", "HTTPS://B/%7Ex") == "https://B/%7Ex"

suite "URLR-04 removeDotSegments":
  # SPEC: URLR-04
  test "Given RFC 3986 §5.2.4 の例と端, When removeDotSegments, Then 規格の結果":
    check removeDotSegments("/a/b/c/./../../g") == "/a/g"
    check removeDotSegments("mid/content=5/../6") == "mid/6"
    check removeDotSegments(".") == ""
    check removeDotSegments("..") == ""
    check removeDotSegments("/..") == "/"
    check removeDotSegments("a//b/./c") == "a//b/c"
    check removeDotSegments("../a/b") == "a/b"
    check removeDotSegments("./a") == "a"

suite "URLR-06 schemeOf":
  # SPEC: URLR-06
  test "Given URL の先頭, When schemeOf, Then 小文字の scheme か空":
    check schemeOf("HTTP://a") == "http"
    check schemeOf("a+b-c.d:x") == "a+b-c.d"
    check schemeOf("1a:x") == ""
    check schemeOf("//a/b") == ""
    check schemeOf("g") == ""
    check schemeOf("") == ""
    check schemeOf(":x") == ""
