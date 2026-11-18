## RFC 3986 §5.2 の参照の解決 (ADR-URLR-0001)。
##
##   let r = resolveReference("http://a/b/c/d;p?q", "../g")
##   if r.isOk: echo r.get   # http://a/b/g
##
## 文字列の形は確かめない (解いた結果を読むのは呼び手)。HTML の href の前後の空白や
## 途中の改行を除く処理 (WHATWG URL の前処理) は持たない: 届いた参照をそのまま解く。

import std/strutils
import nim_outcome

export nim_outcome

type
  UrlParts = object
    scheme: string
    hasAuthority: bool
    authority: string
    path: string
    hasQuery: bool
    query: string
    hasFragment: bool
    fragment: string

const
  ascii0 = {'A'..'Z', 'a'..'z'}
  schemeChars = {'A'..'Z', 'a'..'z', '0'..'9', '+', '-', '.'}

proc schemeOf*(url: string): string {.raises: [], gcsafe.} =
  ## URLR-06。先頭の scheme (小文字)。無ければ ""。
  if url.len == 0 or url[0] notin ascii0: return ""
  var i = 1
  while i < url.len and url[i] in schemeChars: inc i
  if i < url.len and url[i] == ':': url[0 ..< i].toLowerAscii else: ""

proc split(url: string): UrlParts {.raises: [].} =
  ## RFC 3986 付録 B の正規表現と同じ切り方。
  var rest = url
  result.scheme = schemeOf(url)
  if result.scheme.len > 0: rest = rest[result.scheme.len + 1 .. ^1]
  let hash = rest.find('#')
  if hash >= 0:
    result.hasFragment = true
    result.fragment = rest[hash + 1 .. ^1]
    rest = rest[0 ..< hash]
  let q = rest.find('?')
  if q >= 0:
    result.hasQuery = true
    result.query = rest[q + 1 .. ^1]
    rest = rest[0 ..< q]
  if rest.startsWith("//"):
    result.hasAuthority = true
    let slash = rest.find('/', 2)
    if slash < 0:
      result.authority = rest[2 .. ^1]
      rest = ""
    else:
      result.authority = rest[2 ..< slash]
      rest = rest[slash .. ^1]
  result.path = rest

proc removeDotSegments*(path: string): string {.raises: [], gcsafe.} =
  ## URLR-04。RFC 3986 §5.2.4 の手順そのまま。
  var input = path
  var output: seq[string]
  while input.len > 0:
    if input.startsWith("../"): input = input[3 .. ^1]
    elif input.startsWith("./"): input = input[2 .. ^1]
    elif input.startsWith("/./"): input = input[2 .. ^1]
    elif input == "/.": input = "/"
    elif input.startsWith("/../"):
      input = input[3 .. ^1]
      if output.len > 0: output.setLen(output.len - 1)
    elif input == "/..":
      input = "/"
      if output.len > 0: output.setLen(output.len - 1)
    elif input == "." or input == "..": input = ""
    else:
      let next = input.find('/', 1)
      let cut = if next < 0: input.len else: next
      output.add input[0 ..< cut]
      input = input[cut .. ^1]
  output.join("")

proc recompose(p: UrlParts): string {.raises: [].} =
  ## RFC 3986 §5.3。
  if p.scheme.len > 0: result.add p.scheme & ":"
  if p.hasAuthority: result.add "//" & p.authority
  result.add p.path
  if p.hasQuery: result.add "?" & p.query
  if p.hasFragment: result.add "#" & p.fragment

proc resolveReference*(base, reference: string): Outcome[string] {.raises: [], gcsafe.} =
  ## URLR-01〜03。RFC 3986 §5.2.2 (厳密な読み)。参照が scheme を持てば基底は見ない。
  ## そうでなく基底が scheme を持たなければ失敗する (§5.2.1 は絶対の基底を求める)。
  let r = split(reference)
  var t: UrlParts
  if r.scheme.len > 0:
    t = r
    t.path = removeDotSegments(r.path)
    return success(recompose(t))
  let b = split(base)
  if b.scheme.len == 0:
    return failure[string]("the base URI has no scheme: ", base)
  if r.hasAuthority:
    t = r
    t.scheme = b.scheme
    t.path = removeDotSegments(r.path)
  else:
    t.scheme = b.scheme
    t.hasAuthority = b.hasAuthority
    t.authority = b.authority
    if r.path.len == 0:
      t.path = b.path
      if r.hasQuery:
        t.hasQuery = true
        t.query = r.query
      else:
        t.hasQuery = b.hasQuery
        t.query = b.query
    else:
      if r.path.startsWith("/"):
        t.path = removeDotSegments(r.path)
      else:
        var merged: string
        if b.hasAuthority and b.path.len == 0:
          merged = "/" & r.path
        else:
          let slash = b.path.rfind('/')
          merged = (if slash >= 0: b.path[0 .. slash] else: "") & r.path
        t.path = removeDotSegments(merged)
      t.hasQuery = r.hasQuery
      t.query = r.query
  t.hasFragment = r.hasFragment
  t.fragment = r.fragment
  success(recompose(t))
