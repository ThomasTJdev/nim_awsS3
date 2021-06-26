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


const
  mimetypeDB = mimes.toTable


proc jsonUpdate(a:var JsonNode,b:JsonNode) =
  for key,value in b.pairs:
    a[key] = value


proc s3SignedUrl*(awsCreds: AwsCreds, bucketHost, key: string, httpMethod=HttpGet, contentName="", setContentType=true, fileExt="", customQuery="", copyObject=""; expireInSec="65"): string =
  ## Generate a S3 signed URL.
  ##
  ## customQuery:
  ##  This is a custom defined header query. The string needs to include the format
  ##  "head1:value,head2:value" - a comma separated string with header and
  ##  value diveded by colon.
  ## 
  ## fileExt => ".jpg", ".ifc"

  let
    secretKey = awsCreds.AWS_SECRET_ACCESS_KEY
    accessKey = awsCreds.AWS_ACCESS_KEY_ID
    tokenKey  = awsCreds.AWS_SESSION_TOKEN

    url       = "https://" & bucketHost & "/" & key
    region    = awsCreds.AWS_REGION
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
              "X-Amz-Security-Token": tokenKey,
              # "X-Amz-SignedHeaders": "host"
            }

  if contentName != "":
    jsonUpdate(query, %*{"response-content-disposition": "attachment; filename=\"" & contentName & "\""})

  if setContentType:
    let extension = if fileExt != "": fileExt[1..^1] else: splitFile(key).ext[1..^1]
    jsonUpdate(query, %*{"response-content-type": mimetypeDB.getOrDefault(extension, "binary/octet-stream")})

  if customQuery != "":
    for c in split(customQuery, ","):
      let q = split(c, ":")
      jsonUpdate(query, %*{q[0]: q[1]})

  # Add the signed headers to query
  if copyObject != "":
    jsonUpdate(query, %*{"X-Amz-SignedHeaders": "host;x-amz-copy-source"})
  else:
    jsonUpdate(query, %*{"X-Amz-SignedHeaders": "host"})

  let
    request   = canonicalRequest(httpMethod, url, query, headers, payload, digest=UnsignedPayload)
    sts       = stringToSign(request.hash(digest), scope, date=datetime, digest=digest)
    signature = calculateSignature(secret=secretKey, date=datetime, region=region,
                                  service=service, tosign=sts, digest=digest)

  result = url & "?" & request.split("\n")[2] & "&X-Amz-Signature=" & signature

  when defined(dev):
    echo result