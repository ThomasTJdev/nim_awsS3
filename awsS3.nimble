version       = "3.0.0"
author        = "Thomas T. Jarløv (https://github.com/ThomasTJdev)"
description   = "Amazon S3 REST API (basic)"
license       = "MIT"
installDirs   = @["src"]

requires "nim >= 1.4.2"
requires "sigv4 == 1.3.0"
requires "awsSTS >= 1.0.3"
requires "jsony"
requires "nimSHA2"
requires "dotenv"