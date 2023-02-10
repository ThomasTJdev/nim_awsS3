import 
    os,
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options


import
    ../models/models,
    ../signedv2,
    dotenv

proc createMultipartUpload*(
      client: AsyncHttpClient,
      credentials: AwsCredentials,
      bucket: string,
      region: string,
      service="s3",
      args: CreateMultipartUploadCommandInput
    ): Future[CreateMultipartUploadResult] {.async.}  =

    # example request
    # POST /{Key+}?uploads HTTP/1.1
    # Host: Bucket.s3.amazonaws.com
    # x-amz-acl: ACL
    # Cache-Control: CacheControl
    # Content-Disposition: ContentDisposition
    # Content-Encoding: ContentEncoding
    # Content-Language: ContentLanguage
    # Content-Type: ContentType
    # Expires: Expires
    # x-amz-grant-full-control: GrantFullControl
    # x-amz-grant-read: GrantRead
    # x-amz-grant-read-acp: GrantReadACP
    # x-amz-grant-write-acp: GrantWriteACP
    # x-amz-server-side-encryption: ServerSideEncryption
    # x-amz-storage-class: StorageClass
    # x-amz-website-redirect-location: WebsiteRedirectLocation
    # x-amz-server-side-encryption-customer-algorithm: SSECustomerAlgorithm
    # x-amz-server-side-encryption-customer-key: SSECustomerKey
    # x-amz-server-side-encryption-customer-key-MD5: SSECustomerKeyMD5
    # x-amz-server-side-encryption-aws-kms-key-id: SSEKMSKeyId
    # x-amz-server-side-encryption-context: SSEKMSEncryptionContext
    # x-amz-server-side-encryption-bucket-key-enabled: BucketKeyEnabled
    # x-amz-request-payer: RequestPayer
    # x-amz-tagging: Tagging
    # x-amz-object-lock-mode: ObjectLockMode
    # x-amz-object-lock-retain-until-date: ObjectLockRetainUntilDate
    # x-amz-object-lock-legal-hold: ObjectLockLegalHoldStatus
    # x-amz-expected-bucket-owner: ExpectedBucketOwner
    # x-amz-checksum-algorithm: ChecksumAlgorithm

    # Body


    # example response
    # HTTP/1.1 200
    # x-amz-abort-date: AbortDate
    # x-amz-abort-rule-id: AbortRuleId
    # x-amz-server-side-encryption: ServerSideEncryption
    # x-amz-server-side-encryption-customer-algorithm: SSECustomerAlgorithm
    # x-amz-server-side-encryption-customer-key-MD5: SSECustomerKeyMD5
    # x-amz-server-side-encryption-aws-kms-key-id: SSEKMSKeyId
    # x-amz-server-side-encryption-context: SSEKMSEncryptionContext
    # x-amz-server-side-encryption-bucket-key-enabled: BucketKeyEnabled
    # x-amz-request-charged: RequestCharged
    # x-amz-checksum-algorithm: ChecksumAlgorithm
    # <?xml version="1.0" encoding="UTF-8"?>
    # <InitiateMultipartUploadResult>
    #    <Bucket>string</Bucket>
    #    <Key>string</Key>
    #    <UploadId>string</UploadId>
    # </InitiateMultipartUploadResult>

    let endpoint = &"htts://{bucket}.{service}.{region}.amazonaws.com"
    var url = &"{endpoint}/{args.key}?uploads="
    let httpMethod = HttpPost


    if args.acl.isSome():
      client.headers["x-amz-acl="] = $args.acl.get()
    if args.cacheControl.isSome():
      client.headers["Cache-Control="] = args.cacheControl.get()
    if args.contentDisposition.isSome():
      client.headers["Content-Disposition="] = args.contentDisposition.get()
    if args.contentEncoding.isSome():
      client.headers["Content-Encoding="] = args.contentEncoding.get()
    if args.contentLanguage.isSome():
      client.headers["Content-Language="] = args.contentLanguage.get()
    if args.contentType.isSome():
      client.headers["Content-Type="] = args.contentType.get()
    if args.expires.isSome():
      client.headers["Expires="] = $args.expires.get()
    if args.grantFullControl.isSome():
      client.headers["x-amz-grant-full-control="] = args.grantFullControl.get()
    if args.grantRead.isSome():
      client.headers["x-amz-grant-read="] = args.grantRead.get()
    if args.grantReadACP.isSome():
      client.headers["x-amz-grant-read-acp="] = args.grantReadACP.get()
    if args.grantWriteACP.isSome():
      client.headers["x-amz-grant-write-acp="] = args.grantWriteACP.get()
    if args.serverSideEncryption.isSome():
      client.headers["x-amz-server-side-encryption="] = $args.serverSideEncryption.get()
    if args.storageClass.isSome():
      client.headers["x-amz-storage-class="] = $args.storageClass.get()
    if args.websiteRedirectLocation.isSome():
      client.headers["x-amz-website-redirect-location="] = args.websiteRedirectLocation.get()
    if args.sseCustomerAlgorithm.isSome():
      client.headers["x-amz-server-side-encryption-customer-algorithm="] = args.sseCustomerAlgorithm.get()
    if args.sseCustomerKey.isSome():
      client.headers["x-amz-server-side-encryption-customer-key="] = args.sseCustomerKey.get()
    if args.sseCustomerKeyMD5.isSome():
      client.headers["x-amz-server-side-encryption-customer-key-MD5="] = args.sseCustomerKeyMD5.get()
    if args.sseKMSKeyId.isSome():
      client.headers["x-amz-server-side-encryption-aws-kms-key-id="] = args.sseKMSKeyId.get()
    if args.sseKMSEncryptionContext.isSome():
      client.headers["x-amz-server-side-encryption-context="] = args.sseKMSEncryptionContext.get()
    if args.requestPayer.isSome():
      client.headers["x-amz-request-payer="] = args.requestPayer.get()
    if args.tagging.isSome():
      client.headers["x-amz-tagging="] = args.tagging.get()
    if args.objectLockMode.isSome():
      client.headers["x-amz-object-lock-mode="] = $args.objectLockMode.get()
    if args.objectLockRetainUntilDate.isSome():
      client.headers["x-amz-object-lock-retain-until-date="] = $args.objectLockRetainUntilDate.get()
    if args.objectLockLegalHoldStatus.isSome():
      client.headers["x-amz-object-lock-legal-hold="] = $args.objectLockLegalHoldStatus.get()
    if args.expectedBucketOwner.isSome():
      client.headers["x-amz-expected-bucket-owner="] = args.expectedBucketOwner.get()
    if args.checksumAlgorithm.isSome():
      client.headers["x-amz-checksum-algorithm="] = $args.checksumAlgorithm.get()

    # let res = await client.request(httpMethod=httpMethod, url=url, headers = headers, body = "")
    let res = await client.request(credentials, httpMethod, url, region, service, payload="")
    let body = await res.body

    when defined(dev):
        echo "<url: ", url
        echo "<method: ", httpMethod
        echo "<code: ", res.code
        echo "<headers: ", res.headers
        echo "<body: ", body

    if res.code != Http200:
        raise newException(HttpRequestError, "Error: failed to uploadPart: " & $res.code & "\n" & body)




    # result = body.parseXml[CreateMultipartUploadResult]()    


proc main() {.async.} =
    # load .env environment variables
    load()
    # this is just a scoped testing function
    let
        accessKey = os.getEnv("AWS_ACCESS_KEY_ID")
        secretKey = os.getEnv("AWS_SECRET_ACCESS_KEY")
        region = "eu-west-2"
        bucket = "nim-aws-s3-multipart-upload"
        key    = "testFile.bin"

    let credentials = AwsCredentials(id: accessKey, secret: secretKey)

    var client = newAsyncHttpClient()

    let args = CreateMultipartUploadCommandInput(
        bucket: bucket,
        key: key,
    )
    let res = await client.createMultipartUpload(credentials=credentials, bucket=bucket, region=region, args=args)



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