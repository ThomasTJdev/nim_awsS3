import 
    os,
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options


import
    
    ../models/models,
    ../signedV2,
    nimSHA2,
    dotenv





proc uploadPart*[T](
      client: AsyncHttpClient,
      credentials: AwsCredentials,
      bucket: string,
      region: string,
      service="s3",
      args: UploadPartCommandInput[T]
    ): Future[UploadPartResult] {.async.} =

    # example request
    # PUT /Key+?partNumber=PartNumber&uploadId=UploadId HTTP/1.1
    # Host: Bucket.s3.amazonaws.com
    # Content-Length: ContentLength
    # Content-MD5: ContentMD5
    # x-amz-sdk-checksum-algorithm: ChecksumAlgorithm
    # x-amz-checksum-crc32: ChecksumCRC32
    # x-amz-checksum-crc32c: ChecksumCRC32C
    # x-amz-checksum-sha1: ChecksumSHA1
    # x-amz-checksum-sha256: ChecksumSHA256
    # x-amz-server-side-encryption-customer-algorithm: SSECustomerAlgorithm
    # x-amz-server-side-encryption-customer-key: SSECustomerKey
    # x-amz-server-side-encryption-customer-key-MD5: SSECustomerKeyMD5
    # x-amz-request-payer: RequestPayer
    # x-amz-expected-bucket-owner: ExpectedBucketOwner

    # Body


    # example response
    # HTTP/1.1 200
    # x-amz-server-side-encryption: ServerSideEncryption
    # ETag: ETag
    # x-amz-checksum-crc32: ChecksumCRC32
    # x-amz-checksum-crc32c: ChecksumCRC32C
    # x-amz-checksum-sha1: ChecksumSHA1
    # x-amz-checksum-sha256: ChecksumSHA256
    # x-amz-server-side-encryption-customer-algorithm: SSECustomerAlgorithm
    # x-amz-server-side-encryption-customer-key-MD5: SSECustomerKeyMD5
    # x-amz-server-side-encryption-aws-kms-key-id: SSEKMSKeyId
    # x-amz-server-side-encryption-bucket-key-enabled: BucketKeyEnabled
    # x-amz-request-charged: RequestCharged

    
    let url = &"htts://{bucket}.{service}.{region}.amazonaws.com/{args.key}?partNumber={args.partNumber}&uploadId={args.uploadId}"
    let httpMethod = HttpPut

    let res = await client.request(credentials, httpMethod, url, region, service, payload=args.body)
    let body = await res.body
    if res.code != Http200:
        raise newException(HttpRequestError, "Error: failed to uploadPart: " & $res.code & "\n" & body)

    echo "<code: " & $res.code
    echo "<body: " & body
    echo "<headers: " & $res.headers

    # result = body.parseXml[ListMultipartUploadsResult]()

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


    let fileHandle = open("testFile.bin", fmRead)
    let fileSize = fileHandle.getFileSize()

    var fileBuffer = newSeq[byte](fileSize)
    echo fileHandle.readBytes(fileBuffer, 0, fileBuffer.len)

    var body = fileBuffer[0..<(1024*1024*5)]

    let uploadId = "bhsROEtEo6f7QrI3MtxvKmdg_RIZSzu3Sljj0WvmKWMqOIVul3SUPo0GPsuN0vQB9nBh.N19aENUmvnnQeneg3Wnnq21mU28qkuGAQM01KwBSoqSvrd9NvuDvCv_y6BD"

    let uploadPartCommandInput = UploadPartCommandInput[typeof(body)](
        bucket: bucket,
        key: key,
        body: body,
        partNumber: 1,
        uploadId: uploadId
    )
    let res = await client.uploadPart(credentials=credentials, bucket=bucket, region=region, args=uploadPartCommandInput)




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