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

    # example reqeust
    # GET /?uploads&delimiter=Delimiter&encoding-type=EncodingType&key-marker=KeyMarker&max-uploads=MaxUploads&prefix=Prefix&upload-id-marker=UploadIdMarker HTTP/1.1
    # Host: Bucket.s3.amazonaws.com
    # x-amz-expected-bucket-owner: ExpectedBucketOwner

    # example response
    # HTTP/1.1 200
    # <?xml version="1.0" encoding="UTF-8"?>
    # <ListMultipartUploadsResult>
    # <Bucket>string</Bucket>
    # <KeyMarker>string</KeyMarker>
    # <UploadIdMarker>string</UploadIdMarker>
    # <NextKeyMarker>string</NextKeyMarker>
    # <Prefix>string</Prefix>
    # <Delimiter>string</Delimiter>
    # <NextUploadIdMarker>string</NextUploadIdMarker>
    # <MaxUploads>integer</MaxUploads>
    # <IsTruncated>boolean</IsTruncated>
    # <Upload>
    #     <ChecksumAlgorithm>string</ChecksumAlgorithm>
    #     <Initiated>timestamp</Initiated>
    #     <Initiator>
    #         <DisplayName>string</DisplayName>
    #         <ID>string</ID>
    #     </Initiator>
    #     <Key>string</Key>
    #     <Owner>
    #         <DisplayName>string</DisplayName>
    #         <ID>string</ID>
    #     </Owner>
    #     <StorageClass>string</StorageClass>
    #     <UploadId>string</UploadId>
    # </Upload>
    # ...
    # <CommonPrefixes>
    #     <Prefix>string</Prefix>
    # </CommonPrefixes>
    # ...
    # <EncodingType>string</EncodingType>
    # </ListMultipartUploadsResult>
    

    let url = &"/?uploads&delimiter={args.delimiter}&encoding-type={args.encodingType}&key-marker={args.keyMarker}&max-uploads={args.maxUploads}&prefix={args.prefix}&upload-id-marker={args.uploadIdMarker}"
    let httpMethod = HttpGet
    # let authorization = createAuth(creds, url, httpMethod)
    let headers = newHttpHeaders()

    let res = await client.request(httpMethod=httpMethod, url=url, headers = headers, body = "")
    let body = await res.body
    if res.code != Http200:
        raise newException(HttpRequestError, "Error: failed to listMultipartUpload: " & $res.code & "\n" & await res.body)
    
    # result = body.parseXml[ListMultipartUploadsResult]()
