# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk


import
  std/[
    httpclient,
    httpcore,
    json,
    mimetypes,
    os,
    strutils,
    tables,
    times
  ]

import
  awsSigV4,
  awsSTS

type
  S3ContentDisposition* = enum
    CDTinline
    CDTattachment
    CDTignore

const
  mimetypeDB = mimes.toTable

const
  #dateISO8601* = initTimeFormat "yyyyMMdd"
  basicISO8601* = initTimeFormat "yyyyMMdd\'T\'HHmmss\'Z\'"


proc s3SignedUrl*(
    credsAccessKey, credsSecretKey, credsRegion: string,
    bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition: S3ContentDisposition = CDTignore, contentDispositionName = "",
    setContentType = true,
    fileExt = "", customQuery = "", copyObject = "", expireInSec = "65",
    accessToken = "",
    makeDateTime = ""
  ): string =
  ## Generate a S3 signed URL.
  ##
  ## customQuery:
  ##  This is a custom defined header query. The string needs to include the format
  ##  "head1:value,head2:value" - a comma separated string with header and
  ##  value diveded by colon.
  ##
  ## fileExt => ".jpg", ".ifc"

  let
    url = "https://" & bucketHost & "/" & key
    region = credsRegion
    service = "s3"
    payload = ""
    digest = SHA256

  # datetime:
  #
  # Why this? In a complex threaded system Valgrind kept bugging over the
  # times library and not bein able to free the memory. The original
  # makeDateTime() comes from the library awsSigV4, and even with destroy and
  # defer nothing helped on Valgrind.
  #
  # You might never experience this, but if you do, the fix is to create the
  # datetime string outside the procedure within a scoped block and just pass
  # the string.
  var datetime: string = makeDateTime
  if datetime.len == 0:
    datetime = getTime().utc.format(basicISO8601)

  let scope = credentialScope(region=region, service=service, date=datetime)

  var headers = newHttpHeaders()
  headers.add("Host", bucketHost)
  if copyObject.len > 0:
    headers.add("x-amz-copy-source", copyObject)

  # Create the initial JSON query with known fields using %*
  var query = %* {
    "X-Amz-Algorithm": $SHA256,
    "X-Amz-Credential": credsAccessKey & "/" & scope,
    "X-Amz-Date": datetime,
    "X-Amz-Expires": expireInSec
  }

  if accessToken.len > 0:
    query["X-Amz-Security-Token"] = %* accessToken

  if contentDisposition != CDTignore or contentDispositionName.len > 0:
    let dispType = case contentDisposition
      of CDTinline: "inline;"
      of CDTattachment: "attachment;"
      else: ""

    if contentDispositionName.len > 0:
      let filename = if dispType.len == 0:
        "filename=\"" & contentDispositionName & "\""
      else:
        " filename=\"" & contentDispositionName & "\""
      query["response-content-disposition"] = %* (dispType & filename)

  if setContentType:
    let extension = if fileExt.len > 0: fileExt[1..^1]
                    elif splitFile(key).ext.len > 0: splitFile(key).ext[1..^1]
                    else: ""
    query["response-content-type"] = %* mimetypeDB.getOrDefault(extension, "binary/octet-stream")

  if customQuery.len > 0:
    for c in customQuery.split(","):
      let q = c.split(":")
      if q.len == 2:
        query[q[0]] = %* q[1]

  query["X-Amz-SignedHeaders"] = %* (if copyObject.len > 0: "host;x-amz-copy-source" else: "host")

  let
    request = canonicalRequest(httpMethod, url, query, headers, payload, digest = UnsignedPayload)
    sts = stringToSign(request, scope, datetime, digest)
    signature = calculateSignature(
      secret = credsSecretKey,
      date = datetime,
      region = region,
      service = service,
      tosign = sts,
      digest = digest
    )

  result = url & "?" & request.split("\n")[2] & "&X-Amz-Signature=" & signature

  when defined(verboseS3):
    echo result


proc s3SignedUrl*(awsCreds: AwsCreds, bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition: S3ContentDisposition = CDTignore, contentDispositionName = "",
    setContentType = true, fileExt = "", customQuery = "", copyObject = "",
    expireInSec = "65"
  ): string {.deprecated.} =

  return s3SignedUrl(
      awsCreds.AWS_ACCESS_KEY_ID, awsCreds.AWS_SECRET_ACCESS_KEY, awsCreds.AWS_REGION,
      bucketHost, key,
      httpMethod = httpMethod,
      contentDisposition = contentDisposition, contentDispositionName = contentDispositionName,
      setContentType = setContentType,
      fileExt = fileExt, customQuery = customQuery, copyObject = copyObject, expireInSec = expireInSec,
      accessToken = awsCreds.AWS_SESSION_TOKEN
    )



#
# S3 presigned GET
#
proc s3Presigned*(accessKey, secretKey, region: string, bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition: S3ContentDisposition = CDTattachment, contentDispositionName = "",
    setContentType = true, fileExt = "", expireInSec = "65", accessToken = ""
  ): string {.deprecated.} =
  ## Generates a S3 presigned url for sharing.
  ##
  ## contentDisposition => sets "Content-Disposition" type (inline/attachment)
  ## contentDispositionName => sets "Content-Disposition" name
  ## setContentType => sets "Content-Type"
  ## fileExt        => only if setContentType=true
  ##                   if `fileExt = ""` then mimetype is automated
  ##                   needs to be ".jpg" (dot before) like splitFile(f).ext
  return s3SignedUrl(accessKey, secretKey, region, bucketHost, key,
      httpMethod = httpMethod,
      contentDisposition = contentDisposition, contentDispositionName = contentDispositionName,
      setContentType = setContentType,
      fileExt = fileExt, expireInSec = expireInSec, accessToken = accessToken
    )


proc s3Presigned*(creds: AwsCreds, bucketHost, key: string,
    contentDisposition: S3ContentDisposition = CDTattachment, contentDispositionName="",
    setContentType=true, fileExt="", expireInSec="65"): string {.deprecated.} =

  return s3Presigned(
      creds.AWS_ACCESS_KEY_ID, creds.AWS_SECRET_ACCESS_KEY, creds.AWS_REGION,
      bucketHost, key,
      httpMethod = HttpGet,
      contentDisposition = contentDisposition, contentDispositionName = contentDispositionName,
      setContentType = setContentType, fileExt = fileExt, expireInSec = expireInSec,
      accessToken = creds.AWS_SESSION_TOKEN
    )