# Package
version = "0.1.0"
author = "GodsGolemInc"
description = "Resolve a URI reference against a base URI by RFC 3986 section 5.2, dot segments included"
license = "Apache-2.0"
srcDir = "src"

# Dependencies
requires "nim >= 2.0.0"
# Not in the nimble registry, so named by URL.
requires "https://github.com/jasagiri/nim-outcome >= 0.3.0"

task test, "Run tests":
  for f in listFiles("tests/external"):
    if f.endsWith(".nim"):
      exec "nim c -r --hints:off " & f
