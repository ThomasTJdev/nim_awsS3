import 
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options


import
    ../models/models,
    awsSTS

proc createMultipartUpload*(client: AsyncHttpClient, creds: AwsCreds, args: CreateMultipartUploadCommandInput): Future[CreateMultipartUploadResult] {.async.}  =
    # example request
    # POST /Key+?uploadId=UploadId HTTP/1.1
    # Host: Bucket.s3.amazonaws.com
    # x-amz-checksum-crc32: ChecksumCRC32
    # x-amz-checksum-crc32c: ChecksumCRC32C
    # x-amz-checksum-sha1: ChecksumSHA1
    # x-amz-checksum-sha256: ChecksumSHA256
    # x-amz-request-payer: RequestPayer
    # x-amz-expected-bucket-owner: ExpectedBucketOwner
    # x-amz-server-side-encryption-customer-algorithm: SSECustomerAlgorithm
    # x-amz-server-side-encryption-customer-key: SSECustomerKey
    # x-amz-server-side-encryption-customer-key-MD5: SSECustomerKeyMD5
    # <?xml version="1.0" encoding="UTF-8"?>
    # <CompleteMultipartUpload xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    #    <Part>
    #       <ChecksumCRC32>string</ChecksumCRC32>
    #       <ChecksumCRC32C>string</ChecksumCRC32C>
    #       <ChecksumSHA1>string</ChecksumSHA1>
    #       <ChecksumSHA256>string</ChecksumSHA256>
    #       <ETag>string</ETag>
    #       <PartNumber>integer</PartNumber>
    #    </Part>
    #    ...
    # </CompleteMultipartUpload>

    # example response
    # HTTP/1.1 200
    # x-amz-expiration: Expiration
    # x-amz-server-side-encryption: ServerSideEncryption
    # x-amz-version-id: VersionId
    # x-amz-server-side-encryption-aws-kms-key-id: SSEKMSKeyId
    # x-amz-server-side-encryption-bucket-key-enabled: BucketKeyEnabled
    # x-amz-request-charged: RequestCharged
    # <?xml version="1.0" encoding="UTF-8"?>
    # <CompleteMultipartUploadResult>
    #    <Location>string</Location>
    #    <Bucket>string</Bucket>
    #    <Key>string</Key>
    #    <ETag>string</ETag>
    #    <ChecksumCRC32>string</ChecksumCRC32>
    #    <ChecksumCRC32C>string</ChecksumCRC32C>
    #    <ChecksumSHA1>string</ChecksumSHA1>
    #    <ChecksumSHA256>string</ChecksumSHA256>
    # </CompleteMultipartUploadResult>


    let url = &"{endpoint}/{args.key}?uploadId={args.uploadId}"
    let httpMethod = HttpPost

    # let authorization = createAuthorizationHeader(
    #     creds = creds,
    #     httpMethod = HttpPost,
    #     url = url,
    #     headers = client.headers
    # )
    
    let res = await client.request(
        httpMethod = httpMethod,
        url = url
    )

    let body = await res.body
    if res.code != Http200:
        raise newException(HttpRequestError, "Error creating multipart upload: " & $res.code & "\n" & body)
    

    # result = body.parseXml[CreateMultipartUploadResult]()    