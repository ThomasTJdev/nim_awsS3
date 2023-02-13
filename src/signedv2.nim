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
    unicode,
    sugar

import
    dotenv,
    nimSHA2,
    hmac

from awsSTS import AwsCreds

type
  # AwsCredentials* = object
  #   id*: string
  #   secret*: string

  AwsScope* = object
    date*: DateTime
    region*: string
    service*: string

  CanonicalHeaders* = object
    headers*: HttpHeaders
    headersString*: string
    signedHeaders*: string


  CanonicalRequestResult = object
    endpoint: string
    canonicalRequest: string
    canonicalHeaders: CanonicalHeaders
    canonicalPath: string
    canonicalQuery: string
    hashPayload: string
    authorization: string

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

proc createCanonicalQueryString(queryString: string): string =
  var queryParts = queryString.split("&").filter(x => x != "").map(x => x.split("=")).map(x => (x[0], x[1]))
  if queryParts.len == 0:
    return ""
  
  queryParts = queryParts.sortedByIt(it[0])
  return encodeQuery(queryParts, omitEq=false)

  # if query.len < 1:
  #   return result
  # var queryParts = query.split("&").sorted()
  # for part in queryParts:
  #   result.add(uriEncode(part, {'='}))

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

  let tempHeaders = newHttpHeaders()

  for name in headerKeys:
    let loweredName = toLower(name)
    result.signedHeaders.add(loweredName)
    result.signedHeaders.add(';')

    result.headersString.add(loweredName)
    result.headersString.add(':')

    let values: seq[string] = headers.table[name]
    for value in values.items:
      tempHeaders.add(loweredName, value)
      result.headersString.add(condenseWhitespace(value))

    result.headersString.add("\n")

  result.signedHeaders = result.signedHeaders[0..<result.signedHeaders.high]


  result.headers = headers

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
    endpoint = uri.scheme & "://" & uri.hostname 
    canonicalPath = uri.path.createCanonicalPath()
    canonicalQueryString = uri.query.createCanonicalQueryString()

  var hashload = "UNSIGNED-PAYLOAD"
  if computeHash:
    hashload = payload.computeSHA256().hex().toLowerAscii()

  when defined(dev):
    echo "\n> createCanonicalRequest.hashload"
    echo  hashload

  var
    host = if uri.port.len > 0: &"{uri.hostname}:{uri.port}" else: &"{uri.hostname}"

  headers["host"] = host

  if computeHash:
    headers["x-amz-content-sha256"] = hashload

  let
    canonicalHeaders = createCanonicalHeaders(headers)
    canonicalRequest = &"{httpMethod}\n{canonicalPath}\n{canonicalQueryString}\n{canonicalHeaders.headersString}\n{canonicalHeaders.signedHeaders}\n{hashload}"

  when defined(dev):
    echo "\n> createCanonicalRequest.headers"
    echo canonicalHeaders.headers
    echo "\n> createCanonicalRequest.signedHeaders"
    echo canonicalHeaders.signedHeaders
    echo "\n> createCanonicalRequest.canonicalRequest"
    echo canonicalRequest

  result.endpoint = endpoint
  result.canonicalHeaders = canonicalHeaders
  result.canonicalRequest = canonicalRequest
  result.canonicalPath = canonicalPath
  result.canonicalQuery = canonicalQueryString
  result.hashPayload = hashload


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

proc createAuthorizedCanonicalRequest*(
    credentials: AwsCreds,
    httpMethod: HttpMethod,
    url: string,
    payload: seq[byte] | seq[char] | string,
    headers: HttpHeaders,
    scope: AwsScope,
    algorithm: string,
    termination: string
  ): CanonicalRequestResult =
  # https://docs.aws.amazon.com/general/latest/gr/create-signed-request.html
  # Step 1: Create a canonical request
  # Step 2: Create a hash of the canonical request
  # Step 3: Create a string to sign
  # Step 4: Calculate the signature
  # Step 5: Add the signature to the request
  var headers = headers
  headers["x-amz-date"] = scope.date.format(basicISO8601_1)
  # aws hash is sensitive to string | seq[char|byte]
  # create canonical request
  var canonicalRequestResult = createCanonicalRequest(
    headers,
    httpMethod,
    url,
    payload,
    computeHash=true
  )

  # create string to sign
  let to_sign = createSigningString(
    scope,
    canonicalRequestResult.canonicalRequest,
    algorithm,
    termination
  )
  # create signature
  let 
    signingKey = signingKey(credentials.AWS_SECRET_ACCESS_KEY, scope, termination)
    sig = createSignature(signingKey, to_sign)

  # create authorization header
  let authorization = createAuthorizationHeader(
    credentials.AWS_ACCESS_KEY_ID,
    scope,
    canonicalRequestResult.canonicalHeaders.signedHeaders,
    sig,
    algorithm,
    termination
  )
  canonicalRequestResult.authorization = authorization
  return canonicalRequestResult

proc request*(
    client: AsyncHttpClient,
    credentials: AwsCreds,
    httpMethod: HttpMethod,
    headers: HttpHeaders = newHttpHeaders(),
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
  
  var authorizedCanonicalRequest = createAuthorizedCanonicalRequest(
        credentials, 
        httpMethod,
        url,
        payload,
        headers,
        scope,
        algorithm,
        termination
      )

  authorizedCanonicalRequest.canonicalHeaders.headers["authorization"] = authorizedCanonicalRequest.authorization
  var canonicalURL = authorizedCanonicalRequest.endpoint & authorizedCanonicalRequest.canonicalPath & "?" & authorizedCanonicalRequest.canonicalQuery


  when defined(dev):
    echo "\n> request.httpMethod"
    echo httpMethod
    echo "\n> request.url"
    echo canonicalURL
    echo "\n> request.client.httpClient.headers"
    echo authorizedCanonicalRequest.canonicalHeaders.headers
  
  return client.request(url = canonicalURL, httpMethod = httpMethod, headers=authorizedCanonicalRequest.canonicalHeaders.headers, body = $payload)




proc main() {.async.} =
  # load .env environment variables
  load()
  # this is just a scoped testing function
  proc listMultipartUpload(
    client: AsyncHttpClient,
    credentials: AwsCreds,
    bucket: string,
    region: string
  ): Future[string] {.async.} =
    let
      url = &"https://{bucket}.s3.{region}.amazonaws.com/?uploads="
      service = "s3"
      payload = ""
      res = await client.request(credentials=credentials, httpMethod=HttpGet, url=url, region=region, service=service, payload=payload)
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

  let creds = AwsCreds(AWS_ACCESS_KEY_ID: accessKey, AWS_SECRET_ACCESS_KEY: secretKey)

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