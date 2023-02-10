# std
import 
    os,
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options,
    xmlparser,
    xmltree

# other
import
    ../models/models,
    ../signedv2,
    xml2Json,
    json,
    jsony,
    dotenv,
    utils

import
    createMultipartUpload


proc uploadPart*[T](
      client: AsyncHttpClient,
      credentials: AwsCredentials,
      headers: HttpHeaders = newHttpHeaders(),
      bucket: string,
      region: string,
      service="s3",
      args: UploadPartCommandInput[T]
    ): Future[UploadPartResult] {.async.} =
    ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    ## Uploads a part in a multipart upload.
   
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
    
    echo "Shit", httpMethod
    if args.contentLength.isSome():
      headers["Content-Length"] = $args.contentLength.get()
    if args.contentMD5.isSome():
      headers["Content-MD5"] = args.contentMD5.get()
    if args.checksumAlgorithm.isSome():
      headers["x-amz-sdk-checksum-algorithm"] = $args.checksumAlgorithm.get()
    if args.checksumCRC32.isSome():
      headers["x-amz-checksum-crc32"] = args.checksumCRC32.get()
    if args.checksumCRC32C.isSome():
      headers["x-amz-checksum-crc32c"] = args.checksumCRC32C.get()
    if args.checksumSHA1.isSome():
      headers["x-amz-checksum-sha1"] = args.checksumSHA1.get()
    if args.checksumSHA256.isSome():
      headers["x-amz-checksum-sha256"] = args.checksumSHA256.get()
    if args.sseCustomerAlgorithm.isSome():
      headers["x-amz-server-side-encryption-customer-algorithm"] = args.sseCustomerAlgorithm.get()
    if args.sseCustomerKey.isSome():
      headers["x-amz-server-side-encryption-customer-key"] = args.sseCustomerKey.get()
    if args.sseCustomerKeyMD5.isSome():
      headers["x-amz-server-side-encryption-customer-key-MD5"] = args.sseCustomerKeyMD5.get()
    if args.requestPayer.isSome():
      headers["x-amz-request-payer"] = args.requestPayer.get()
    if args.expectedBucketOwner.isSome():
      headers["x-amz-expected-bucket-owner"] = args.expectedBucketOwner.get()

    let res = await client.request(credentials=credentials, headers=headers, httpMethod=httpMethod, url=url, region=region, service=service, payload=args.body)
    let body = await res.body
    if res.code != Http200:
        raise newException(HttpRequestError, "Error: failed to uploadPart: " & $res.code & "\n" & body)

    if res.code != Http200:
        raise newException(HttpRequestError, "Error: " & $res.code & " " & await res.body)

    let xml = body.parseXML()
    let json = xml.xml2Json()
    let jsonStr = json.toJson()
    echo jsonStr
    let obj = jsonStr.fromJson(UploadPartResult)

    when defined(dev):
        echo "\n> xml: ", xml
        echo "\n> jsonStr: ", jsonStr
        # echo obj
        # echo "\n> obj string: ", obj.toJson().parseJson().pretty()
    result = obj
    


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

    let args = CreateMultipartUploadCommandInput(
        bucket: bucket,
        key: key,
    )
    let createMultiPartUploadResult = await client.createMultipartUpload(credentials=credentials, bucket=bucket, region=region, args=args)

    let uploadPartCommandInput = UploadPartCommandInput[typeof(body)](
        bucket: bucket,
        key: key,
        body: body,
        partNumber: 1,
        uploadId: createMultiPartUploadResult.uploadId
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