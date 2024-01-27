version       = "3.1.0"
author        = "Thomas T. Jarløv (https://github.com/ThomasTJdev)"
description   = "Amazon S3 REST API (basic)"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.4.2"
requires "https://github.com/ThomasTJdev/nim_awsSigV4 >= 0.0.1"
requires "awsSTS >= 1.0.3"
requires "jsony == 1.1.5"

when defined(s3multipart):
  requires "nimSHA2"
  when NimMajor >= 2:
    requires "hmac == 0.3.2"
  else:
    requires "hmac == 0.2.0"