# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk


import
  std/httpclient,
  std/httpcore,
  std/json,
  std/mimetypes,
  std/os,
  std/strutils,
  std/tables


import
  awsSTS,
  sigv4

type
  S3ContentDisposition* = enum
    CDTinline
    CDTattachment
    CDTignore

const
  mimetypeDB = mimes.toTable


proc s3SignedUrl*(
    credsAccessKey, credsSecretKey, credsRegion: string,
    bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition = CDTignore, contentDispositionName = "",
    setContentType = true,
    fileExt = "", customQuery = "", copyObject = "", expireInSec = "65",
    accessToken = ""
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
    accessKey = credsAccessKey
    secretKey = credsSecretKey
    tokenKey  = accessToken

    url       = "https://" & bucketHost & "/" & key
    region    = credsRegion
    service   = "s3"

    payload   = ""
    digest    = SHA256
    expireSec = expireInSec
    datetime  = makeDateTime()
    scope     = credentialScope(region=region, service=service, date=datetime)

  var
    headers = newHttpHeaders(@[
      ("Host", bucketHost)
    ])

  # Attach copyObject to headers
  if copyObject != "":
    headers.add("x-amz-copy-source", copyObject)

  var
    query = %*{
              "X-Amz-Algorithm": $SHA256,
              "X-Amz-Credential": accessKey & "/" & scope,
              "X-Amz-Date": datetime,
              "X-Amz-Expires": expireSec,
              # "X-Amz-SignedHeaders": "host"
            }

  if tokenKey != "":
    query["X-Amz-Security-Token"] = newJString(tokenKey)


  if contentDisposition != CDTignore or contentDispositionName != "":
    let dispType =
        case contentDisposition
        of CDTinline:
          "inline;"
        of CDTattachment:
          "attachment;"
        else:
          ""

    let filename =
        if contentDispositionName == "":
          ""
        elif dispType == "":
          "filename=\"" & contentDispositionName & "\""
        else:
          " filename=\"" & contentDispositionName & "\""

    query["response-content-disposition"] = newJString(dispType & filename)


  if setContentType:
    let extension =
        if fileExt != "":
          fileExt[1..^1]
        else:
          splitFile(key).ext[1..^1]

    query["response-content-type"] = newJString(mimetypeDB.getOrDefault(extension, "binary/octet-stream"))


  if customQuery != "":
    for c in split(customQuery, ","):
      let q = split(c, ":")
      query[q[0]] = newJString(q[1])


  # Add the signed headers to query
  if copyObject != "":
    query["X-Amz-SignedHeaders"] = newJString("host;x-amz-copy-source")
  else:
    query["X-Amz-SignedHeaders"] = newJString("host")


  let
    request   = canonicalRequest(httpMethod, url, query, headers, payload, digest = UnsignedPayload)
    sts       = stringToSign(request.hash(digest), scope, date = datetime, digest = digest)
    signature = calculateSignature(secret=secretKey, date = datetime, region = region,
                                  service = service, tosign = sts, digest = digest)

  result = url & "?" & request.split("\n")[2] & "&X-Amz-Signature=" & signature

  when defined(dev):
    echo result


proc s3SignedUrl*(awsCreds: AwsCreds, bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition = CDTignore, contentDispositionName = "",
    setContentType = true, fileExt = "", customQuery = "", copyObject = "",
    expireInSec = "65"
  ): string =

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
    contentDisposition = CDTattachment, contentDispositionName = "",
    setContentType = true, fileExt = "", expireInSec = "65", accessToken = ""
  ): string =
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
    contentDisposition = CDTattachment, contentDispositionName="",
    setContentType=true, fileExt="", expireInSec="65"): string =

  return s3Presigned(
      creds.AWS_ACCESS_KEY_ID, creds.AWS_SECRET_ACCESS_KEY, creds.AWS_REGION,
      bucketHost, key,
      httpMethod = HttpGet,
      contentDisposition = contentDisposition, contentDispositionName = contentDispositionName,
      setContentType = setContentType, fileExt = fileExt, expireInSec = expireInSec,
      accessToken = creds.AWS_SESSION_TOKEN
    )