version       = "3.0.4"
author        = "Thomas T. Jarløv (https://github.com/ThomasTJdev)"
description   = "Amazon S3 REST API (basic)"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.4.2"
requires "sigv4 == 1.3.0"
requires "awsSTS >= 1.0.3"
requires "jsony == 1.1.5"
requires "nimSHA2"
when NimMajor >= 2:
  requires "hmac == 0.3.2"
else:
  requires "hmac == 0.2.0"