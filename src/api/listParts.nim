import 
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options


import
    ../models/models,
    awsSTS



proc listMultipartUpload*(client: AsyncHttpClient, creds: AwsCreds, args: ListMultipartUploadsRequest): Future[ListMultipartUploadsResult] {.async.} =
    # example request
    # GET /Key+?max-parts=MaxParts&part-number-marker=PartNumberMarker&uploadId=UploadId HTTP/1.1
    # Host: Bucket.s3.amazonaws.com
    # x-amz-request-payer: RequestPayer
    # x-amz-expected-bucket-owner: ExpectedBucketOwner
    # x-amz-server-side-encryption-customer-algorithm: SSECustomerAlgorithm
    # x-amz-server-side-encryption-customer-key: SSECustomerKey
    # x-amz-server-side-encryption-customer-key-MD5: SSECustomerKeyMD5
    
    # example response
    # HTTP/1.1 200
    # x-amz-abort-date: AbortDate
    # x-amz-abort-rule-id: AbortRuleId
    # x-amz-request-charged: RequestCharged
    # <?xml version="1.0" encoding="UTF-8"?>
    # <ListPartsResult>
    #    <Bucket>string</Bucket>
    #    <Key>string</Key>
    #    <UploadId>string</UploadId>
    #    <PartNumberMarker>integer</PartNumberMarker>
    #    <NextPartNumberMarker>integer</NextPartNumberMarker>
    #    <MaxParts>integer</MaxParts>
    #    <IsTruncated>boolean</IsTruncated>
    #    <Part>
    #       <ChecksumCRC32>string</ChecksumCRC32>
    #       <ChecksumCRC32C>string</ChecksumCRC32C>
    #       <ChecksumSHA1>string</ChecksumSHA1>
    #       <ChecksumSHA256>string</ChecksumSHA256>
    #       <ETag>string</ETag>
    #       <LastModified>timestamp</LastModified>
    #       <PartNumber>integer</PartNumber>
    #       <Size>integer</Size>
    #    </Part>
    #    ...
    #    <Initiator>
    #       <DisplayName>string</DisplayName>
    #       <ID>string</ID>
    #    </Initiator>
    #    <Owner>
    #       <DisplayName>string</DisplayName>
    #       <ID>string</ID>
    #    </Owner>
    #    <StorageClass>string</StorageClass>
    #    <ChecksumAlgorithm>string</ChecksumAlgorithm>
    # </ListPartsResult>

    let url = &"/{args.key}?max-parts={args.maxParts}&part-number-marker={args.partNumberMarker}&uploadId={args.uploadId}"
    let httpMethod = HttpGet
    # let authorization = createAuth(creds, url, httpMethod)
    let headers = newHttpHeaders()

    let res = await client.request(httpMethod=httpMethod, url=url, headers = headers, body = "")
    let body = await res.body
    if res.code != Http200:
        raise newException(HttpRequestError, "Error: " & $res.code & " " & await res.body)
    
    # result = body.parseXml[ListMultipartUploadsResult]()
