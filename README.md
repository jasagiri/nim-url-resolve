# nim-url-resolve

URI の参照を基底の URI に対して RFC 3986 §5.2 で解く。§5.2.4 の dot segment の除去も含む。
std/uri の `combine` は末尾の `.`・`..` を除かず、段の途中の `..` を縮める (nim-lang/Nim PR #26290)。
この部品はその代わりになる。規則は `docs/adr/ADR-URLR-0001-rfc3986-resolution.md` (URLR-01〜06)、E テストは `tests/external/` にある。

## API

`import nim_url_resolve`。どれも `{.raises: [], gcsafe.}`。

- `resolveReference*(base, reference: string): Outcome[string]`: RFC 3986 §5.2.2。参照も基底も scheme を持たなければ失敗を返す
- `removeDotSegments*(path: string): string`: §5.2.4
- `schemeOf*(url: string): string`: 先頭の scheme を小文字で返す。無ければ ""

```nim
import nim_url_resolve

let r = resolveReference("http://a/b/c/d;p?q", "../g")
if r.isOk: echo r.get      # http://a/b/g
```

文字列の形は確かめない。結果を URL として読んで確かめるのは呼び手 (`parseUri` など)。
HTML の href の前処理 (前後の空白類、途中のタブ・改行) もしない。

## 依存

`nim-outcome`。テストは `nim-propcheck`。`nim.cfg` の `--path` で隣のディレクトリを読む。

## テスト

```bash
nimble --useSystemNim test   # tests/external/*.nim
```

## 確かめていないこと

- 変異検査 (G2): 2026-11-19 に 94.39%。生き残りの 6 件はどれも等価 (`docs/quality/g2-mutation.md`)。
- ファジングは流していない。性質のテストは、4 種と 8 種の文字から作った文字列だけ。
