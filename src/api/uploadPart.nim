import 
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options


import
    ../models/models,
    awsSTS



proc uploadPart*(client: AsyncHttpClient, creds: AwsCreds, args: UploadPartCommandInput): Future[UploadPartOutput] {.async.} =
    
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

    let url = &"/key?partNumber={args.partNumber}&uploadId={args.uploadId}"
    let httpMethod = HttpPut
    # let authorization = createAuth(creds, url, httpMethod)
    let headers = newHttpHeaders()

    let res = await client.request(httpMethod=httpMethod, url=url, headers = headers, body = "")
    let body = await res.body
    if res.code != Http200:
        raise newException(HttpRequestError, "Error: failed to uploadPart: " & $res.code & "\n" & await res.body)
    
    # result = body.parseXml[ListMultipartUploadsResult]()
