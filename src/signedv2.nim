import 
    os,
    times,
    tables,
    sequtils,
    strutils, strformat, re,
    uri,
    httpclient,
    asyncdispatch,
    algorithm,
    unicode

import
    dotenv,
    nimSHA2,
    hmac

type
  AwsCredentials* = object
    id*: string
    secret*: string

  AwsScope* = object
    date*: DateTime
    region*: string
    service*: string

  CanonicalHeaders* = object
    headers*: string
    signedHeaders*: string

const
  basicISO8601_1 = initTimeFormat "yyyyMMdd\'T\'HHmmss\'Z\'"

# canonical headers, path, qs, encodeUri from 
# https://github.com/Gooseus/nimaws
proc uriEncode(
    s: string,
    notEncode: set[char]
  ): string =
  for i in 0..(s.len - 1):
    if s[i] in notEncode+{'a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~'}:
      result.add(s[i])
    else:
      result.add('%')
      result.add(toHex(ord(s[i]), 2).toUpperASCII())

proc condenseWhitespace(x: string): string =
  return strutils.strip(x).replace(re"\s+", " ")

proc createCanonicalPath(path: string): string =
  return uriEncode(path, {'/'})

proc createCanonicalQueryString(query: string): string =
  if query.len < 1:
    return result
  var queryParts = query.split("&").sorted()
  for part in queryParts:
    result.add(uriEncode(part, {'='}))

proc createSigningString*(
    scope: AwsScope,
    request: string,
    algorithm: string,
    termination: string
  ): string =

  var
    requestSHA256 = computeSHA256(request).hex().toLowerAscii()
    date = scope.date.format("yyyyMMdd")
    fullDate = scope.date.format(basicISO8601_1)
    region = scope.region
    service = scope.service
    scopeString = &"{date}/{region}/{service}"

  return &"{algorithm}\n{fullDate}\n{scopeString}/{termination}\n{requestSHA256}"

proc createCanonicalHeaders(headers: HttpHeaders): CanonicalHeaders =
  var headerKeys = headers.table.keys.toSeq()
  headerKeys = headerKeys.sorted()

  for name in headerKeys:
    let loweredName = toLower(name)

    result.signedHeaders.add(loweredName)
    result.signedHeaders.add(';')

    result.headers.add(loweredName)
    result.headers.add(':')

    let values: seq[string] = headers.table[name]
    for value in values.items:
      result.headers.add(condenseWhitespace(value))

    result.headers.add("\n")

  result.signedHeaders = result.signedHeaders[0..<result.signedHeaders.high]

type CanonicalRequestResult = object
  canonicalRequest: string
  signedHeaders: string

proc computeSHA256*(data: seq[byte] | seq[char]): SHA256Digest =
  var ctx: SHA256
  ctx.initSHA()
  ctx.update(data)
  return ctx.final()

proc createCanonicalRequest*(
    headers: HttpHeaders,
    httpMethod: HttpMethod,
    url: string,
    payload: seq[byte] | seq[char] | string,
    computeHash = true
  ): CanonicalRequestResult =

  let
    uri = url.parseUri()
    cpath = uri.path.createCanonicalPath()
    cquery = uri.query.createCanonicalQueryString()

  var hashload = "UNSIGNED-PAYLOAD"
  if computeHash:
    hashload = payload.computeSHA256().hex().toLowerAscii()

  when defined(dev):
    echo ">hashload: ", hashload

  var
    host = if uri.port.len > 0: &"{uri.hostname}:{uri.port}" else: &"{uri.hostname}"

  headers["host"] = host

  if computeHash:
    headers["x-amz-content-sha256"] = hashload

  let
    canonicalHeaders = createCanonicalHeaders(headers)
    canonicalRequest = &"{httpMethod}\n{cpath}\n{cquery}\n{canonicalHeaders.headers}\n{canonicalHeaders.signedHeaders}\n{hashload}"

  when defined(dev):
    echo ">canonicalRequest: ", canonicalRequest
    echo ">\n"

  result.signedHeaders = canonicalHeaders.signedHeaders
  result.canonicalRequest = canonicalRequest


proc createSignature*(key: string, sts: string): string =
  return hmac_sha256(key, sts).hex().toLowerAscii()

proc signingKey*(
    secret: string,
    scope: AwsScope,
    termination: string
    ): string =

  var
    date = scope.date.format("yyyyMMdd")
    region = scope.region
    service = scope.service

    kDate = $hmac_sha256(&"AWS4{secret}", date)
    kRegion = $hmac_sha256(kDate, region)
    kService = $hmac_sha256(kRegion, service)
    kSigning = $hmac_sha256(kService, termination)
  return kSigning

proc createAuthorizationHeader*(
    id: string,
    scope: AwsScope,
    signedHeaders,
    signature: string,
    algorithm: string,
    termination: string
    ): string =
  var
    date = scope.date.format("yyyyMMdd")
    scopeString = &"{date}/{scope.region}/{scope.service}"
    credential = &"{id}/{scopeString}/{termination}"

  return &"{algorithm} Credential={credential}, SignedHeaders={signedHeaders}, Signature={signature}"

proc createAuthaurization*(
    id: string,
    key: string,
    # request: AwsRequest,
    httpMethod: HttpMethod,
    url: string,
    payload: seq[byte] | seq[char] | string,
    headers: HttpHeaders,
    scope: AwsScope,
    algorithm: string,
    termination: string
  ): string =
  # https://docs.aws.amazon.com/general/latest/gr/create-signed-request.html
  # Step 1: Create a canonical request
  # Step 2: Create a hash of the canonical request
  # Step 3: Create a string to sign
  # Step 4: Calculate the signature
  # Step 5: Add the signature to the request

  headers["x-amz-date"] = scope.date.format(basicISO8601_1)
  # aws hash is sensitive to string | seq[char|byte]
  # create canonical request
  let canonicalRequestResult = createCanonicalRequest(
    headers,
    httpMethod,
    url,
    payload,
    computeHash=true
  )
  headers.del("host")

  # create string to sign
  let to_sign = createSigningString(
    scope,
    canonicalRequestResult.canonicalRequest,
    algorithm,
    termination
  )
  # create signature
  let sig = createSignature(key, to_sign)

  # create authorization header
  return createAuthorizationHeader(
    id,
    scope,
    canonicalRequestResult.signedHeaders,
    sig,
    algorithm,
    termination
  )

proc createAuth*(
    creds: AwsCredentials,
    httpMethod: HttpMethod,
    url: string,
    payload: seq[byte] | seq[char] | string,
    headers: HttpHeaders,
    scope: AwsScope,
    algorithm: string,
    termination: string
    ): string =
  var
    signingKey = signingKey(creds.secret, scope, termination)
    authorization = createAuthaurization(
      creds.id,
      signingKey,
      httpMethod,
      url,
      payload,
      headers,
      scope,
      algorithm,
      termination
    )

  # headers["authorization"] = authorization
  return authorization


proc request*(
    client: AsyncHttpClient,
    credentials: AwsCredentials,
    httpMethod: HttpMethod,
    url: string,
    region: string,
    service: string,
    payload: seq[byte] | seq[char] | string,
    algorithm = "AWS4-HMAC-SHA256",
    termination = "aws4_request"
  ): Future[AsyncResponse] =

  let
    date = getTime().utc()
    scope = AwsScope(date: date, region: region, service: service)
    auth = createAuth(credentials, httpMethod, url, payload, client.headers, scope,
        algorithm, termination)

  client.headers["Authorization"] = auth

  when defined(dev):
    echo "httpMethod"
    echo httpMethod
    echo "url"
    echo url
    echo "client.httpClient.headers"
    echo client.headers

  return client.request(url = url, httpMethod = httpMethod, body = $payload)




proc main() {.async.} =
  # load .env environment variables
  load()
  # this is just a scoped testing function
  proc listMultipartUpload(
    client: AsyncHttpClient,
    credentials: AwsCredentials,
    bucket: string,
    region: string
  ): Future[string] {.async.} =
    let
      url = &"https://{bucket}.s3.{region}.amazonaws.com/?uploads="
      service = "s3"
      payload = ""
      res = await client.request(credentials, HttpGet, url, region, service, payload)
      body = await res.body

    if res.code != Http200:
      raise newException(HttpRequestError, "Failed to list multipart upload: " &
          $res.code & " " & body)
    return body

  let
    accessKey = os.getEnv("AWS_ACCESS_KEY_ID")
    secretKey = os.getEnv("AWS_SECRET_ACCESS_KEY")
    region = "eu-west-2"
    bucket = "nim-aws-s3-multipart-upload"

  let creds = AwsCredentials(id: accessKey, secret: secretKey)

  var client = newAsyncHttpClient()
  echo await client.listMultipartUpload(creds, bucket, region)


when isMainModule:
  try:
    waitFor main()
  except:
    ## treeform async message fix
    ## https://github.com/nim-lang/Nim/issues/19931#issuecomment-1167658160
    let msg = getCurrentExceptionMsg()
    for line in msg.split("\n"):
      var line = line.replace("\\", "/")
      if "/lib/pure/async" in line:
        continue
      if "#[" in line:
        break
      line.removeSuffix("Iter")
      echo line