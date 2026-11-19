# 変異検査 (G2) — nim_url_resolve.nim

**対象**: `src/nim_url_resolve.nim`。**設定**: `tests/mutation/url_resolve.json` (`tests/external` の 2 本を流す)。

**測定**: 2026-11-19、変異検査の道具 0.2.18、Nim 2.4.2。

| 回 | killed | survived | timeout | compileErr | total | 得点 |
|---|---|---|---|---|---|---|
| 1 回目 | 94 | 13 | 4 | 5 | 116 | 87.85% |
| 2 回目 (E テストを足した後) | 101 | 6 | 4 | 5 | 116 | 94.39% |

得点は killed ÷ (killed + survived)。timeout の 4 件 (33 行の `inc i` の削除、66・70・74 行の比較の反転) は、どれも `while` が終わらなくなる変異で、単独で流し直しても時間切れになった。compileErr の 5 件は、集合の範囲 (`'A'..'Z'` など) の変異でコンパイルできないもの。

## 1 回目の生き残りから足した E テスト

- URLR-01: 段が 1 つの基底の path (`http://a/c` に `g`) の merge。130 行の `slash >= 0` の変異 2 件を殺した。
- URLR-01: 空の authority の参照 (`///../g`)。53 行の `find('/', 2)` の開始位置の変異を殺した。
- URLR-02: 失敗の理由が基底を示すこと。104 行の失敗を既定値に替える変異を殺した。
- URLR-04: `removeDotSegments("../a/b")`・`("./a")`。67 行の `input[3 .. ^1]` の変異 3 件を殺した。

## 生き残った変異 (6 件、どれも等価)

1 件ずつの理由は `survivors-url_resolve.json`。要約:

- 31 行: `return ""` と `return default` は同じ値。
- 54 行 (2 件)・80 行 (2 件): `find` の結果は -1 か開始位置以上なので、`< 0`・`<= 0`・`< 1` は同じ。
- 87 行: `recompose` は scheme が空でないときにしか呼ばれない。
