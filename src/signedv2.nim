import
  asyncdispatch,
  httpclient,
  uri,
  os,
  options,
  times,
  strutils,
  net,
  strformat,
  tables

import
  # awsS3,
  # ./multipartUpload,
  # awsSTS,
  sigv4,
  nimcrypto/hmac,
  json,
  nimSHA2

import
  algorithm,
  sequtils,
  strutils,
  sugar,
  re

type
  CanonicalRequestResult = object
    signedHeaders: string
    hashPayload: string
    canonicalRequestHash: string

type
  SignedRequestResult = object
    hashPayload: string
    authorization: string

type
  AwsScope = object
    date: DateTime
    region: string
    service: string
    request: string

const
  basicISO8601_1 = initTimeFormat "yyyyMMdd\'T\'HHmmss\'Z\'"
  # basicISO8601_2 = initTimeFormat "yyyy-MM-dd\'T\'HH:mm:ss'.000'\'Z\'"

proc sign(digest = sha256, key, message: string): string =
  var
    hmac = $hmac.hmac(digest, key, message)
  result = hmac.toLowerAscii() # hmac.hex.toLowerAscii


proc createCanonicalUri(uri: string): string =
  return uri

proc createCanonicalQueryString(queryString: string): string =
  return queryString.encodeUrl()


proc createCanonicalSignedHeaders(headers: seq[string]): string =
  # sort by key by alphabetical order
  # convert to lowercase
  # trim whitespace
  # restrict whitespace to a single space
  # join headers with (;)
  # example: content-type:application/x-www-form-urlencoded; charset=utf-8 host:ec2.amazonaws.com x-amz-date:20220830T123600Z

  result = headers.map(h => h.toLowerAscii().strip().replace("  ", " ")).sorted().join(";")

  when defined(dev):
    echo "\n== createCanonicalSignedHeaders =="
    echo result

proc createCanonicalHeaders(headers: HttpHeaders): string =
  # sort by key by alphabetical order
  # convert to lowercase
  # trim whitespace
  # restrict whitespace to a single space
  # headers must be Key:Value
  # join headers with (;)
  # example: content-type:application/x-www-form-urlencoded; charset=utf-8 host:ec2.amazonaws.com x-amz-date:20220830T123600Z
  var headerKeys = headers.table.keys.toSeq()
  headerKeys = headerKeys.map(h => h.toLowerAscii().strip().replace(re"\s+", " "))
  headerKeys = headerKeys.sorted()
  for key in headerKeys:
    var value = headers[key].strip().replace(re"\s+", " ")
    result.add(&"{key}:{value};")

  when defined(dev):
    echo "\n== createCanonicalHeaders =="
    echo result

proc createConicalRequest(headers: HttpHeaders, signedHeaders: seq[string],
    action: HttpMethod, url, payload: string): CanonicalRequestResult =
  var
    uri = url.parseUri() # example: "https://ec2.amazonaws.com/?Action=ListUsers&Version=2010-05-08"
    canonicalUri = uri.path.createCanonicalUri()         # example: "/"
    canonicalQueryString = uri.query.createCanonicalQueryString() # example: "Action=ListUsers&Version=2010-05-08"
    hashPayload = payload.computeSHA256().hex().toLowerAscii() 
  
  headers.add("x-amz-content-sha256", hashPayload)

  var
    canonicalHeaders = headers.createCanonicalHeaders() # exmaple content-type:application/x-www-form-urlencoded; charset=utf-8 host:ec2.amazonaws.com x-amz-date:20220830T123600Z
    canonicalSignedheaders = signedHeaders.createCanonicalSignedHeaders() # example "host;x-amz-content-sha256;x-amz-date"


  var canonicalRequest = &"{action}\n{canonicalUri}\n{canonicalQueryString}\n{canonicalHeaders}\n\n{signedHeaders}\n{hashPayload}"

  result.signedHeaders = canonicalSignedheaders
  result.hashPayload = hashPayload
  result.canonicalRequestHash = canonicalRequest.computeSHA256().hex().toLowerAscii()



proc createSigningKey(secretKey: string, scope: AwsScope): string =
  var
    kDate = sign(sha256, &"AWS4{secretKey}", scope.date.format("yyyyMMdd"))
    kRegion = sign(sha256, kDate, scope.region)
    kService = sign(sha256, kRegion, scope.service)
    kSigning = sign(sha256, kService, "aws4_request")
  result = kSigning


proc createSignedRequest(
    algorithm = SigningAlgo.SHA256, # example: AWS4-HMAC-SHA256
    headers: HttpHeaders,
    signedHeaders: seq[string], # must exist in headers
    action: HttpMethod,
    url, payload, accessKey, secretKey: string,
    scope: AwsScope
  ): SignedRequestResult =
  # https://docs.aws.amazon.com/general/latest/gr/create-signed-request.html
  # Step 1: Create a canonical request
  # Step 2: Create a hash of the canonical request
  # Step 3: Create a string to sign
  # Step 4: Calculate the signature
  # Step 5: Add the signature to the request
  var
    date = scope.date.format("yyyyMMdd")
    region = scope.region
    service = scope.service
    # 1. Create a canonical request
    canonicalRequest = createConicalRequest(
        headers = headers,
        signedHeaders=signedHeaders,
        action = action,
        url = url,
        payload = payload
    )
    # 2. Create a hash of the canonical request
    signedHeaders = canonicalRequest.signedHeaders # example: "host;x-amz-content-sha256;x-amz-date"
    hashPayload = canonicalRequest.hashPayload # example: "UNSIGNED-PAYLOAD" | "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    canonicalRequestHash = canonicalRequest.canonicalRequestHash # example "f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59"
    # 3. Create a string to sign
    key = createSigningKey(secretKey, scope)
    # 4. Calculate the signature
    credential = &"{accessKey}/{date}/{region}/{service}/aws4_request"
    # signedRequest: https://docs.aws.amazon.com/general/latest/gr/create-signed-request.html#create-string-to-sign
    signedRequest = &"{algorithm}\n{date}\n{credential}\n{canonicalRequestHash}"
    signature = sign(key = key, message = signedRequest)
    authorization = &"{algorithm} Credential={credential}, SignedHeaders={signedHeaders}, Signature={signature}"

  # 4. Add the signature to the request
  result.hashPayload = hashPayload
  result.authorization = authorization
  when(defined(dev)):
    echo "\n== createSignedRequest =="
    echo "key: ", key
    echo "\n"
    echo "canonicalRequest: \n", canonicalRequest
    echo "\n"
    echo "signedRequest: \n", signedRequest
    echo "\n"
    echo "signature: ", signature



proc main() {.async.} =

  let
    region = "eu-west-2"
    # role     = "arn:aws:iam::779135355686:role/nim-multipart-dev-role"

    accessKey = "AKIA3K2AWBMTIA5B2ZCV"
    secretKey = "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"
    # bucketName = "nim-aws-s3-multipart-upload"
    # bucketHost = "localhost:3000"
    host = "nim-aws-s3-multipart-upload.s3.eu-west-2.amazonaws.com"
    # host       = "localhost:3000"
    # key        = "testFile.bin"
    # file       = "testFile.bin"

  var
    service = "s3"
    digest = SigningAlgo.SHA256 # AWS4-HMAC-SHA256
    rawTime = getTime().utc()
    scope = AwsScope(date: rawTime, region: region, service: service)
    # version    = "2010-05-08"
    # url        = "https://localhost:3000/testFile.bin"
    url = "https://nim-aws-s3-multipart-upload.s3.eu-west-2.amazonaws.com/?uploads="
    payload = ""
    httpMethod = HttpGet


  var headers = newHttpHeaders(@[
    ("host", host),
    ("user-agent", "aws-sdk-nim/0.1 (nim 1.6; darwin; arm64)"),
    ("x-amz-date", scope.date.format(basicISO8601_1))
  ])

  var signedRequest = createSignedRequest(
    algorithm = digest,
    headers = headers,
    signedHeaders = @["host", "x-amz-content-sha256", "x-amz-date"],
    action = httpMethod,
    url = url,
    payload = payload,
    accessKey = accessKey,
    secretKey = secretKey,
    scope
  )

  # temporary security credentials
  # headers.add("x-amz-security-token", sessionToken)
  # headers.add("x-amz-expires", "86400")
  headers.add("authorization", signedRequest.authorization)
  headers.add("x-amz-content-sha256", signedRequest.hashPayload)

  # var ctx = newContext(cafile = "server.cert")
  # var client = newAsyncHttpClient(sslContext = ctx)
  var client = newAsyncHttpClient()
  var body = ""

  let res = await client.request(
    url = url,
    httpMethod = httpMethod,
    headers = headers,
    body = body
  )
  echo res.code

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
