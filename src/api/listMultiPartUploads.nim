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

    # GET /?uploads&delimiter=Delimiter&encoding-type=EncodingType&key-marker=KeyMarker&max-uploads=MaxUploads&prefix=Prefix&upload-id-marker=UploadIdMarker HTTP/1.1
    # Host: Bucket.s3.amazonaws.com
    # x-amz-expected-bucket-owner: ExpectedBucketOwner

    # example response
    # HTTP/1.1 200
    # <?xml version="1.0" encoding="UTF-8"?>
    # <ListMultipartUploadsResult>
    #    <Bucket>string</Bucket>
    #    <KeyMarker>string</KeyMarker>
    #    <UploadIdMarker>string</UploadIdMarker>
    #    <NextKeyMarker>string</NextKeyMarker>
    #    <Prefix>string</Prefix>
    #    <Delimiter>string</Delimiter>
    #    <NextUploadIdMarker>string</NextUploadIdMarker>
    #    <MaxUploads>integer</MaxUploads>
    #    <IsTruncated>boolean</IsTruncated>
    #    <Upload>
    #       <ChecksumAlgorithm>string</ChecksumAlgorithm>
    #       <Initiated>timestamp</Initiated>
    #       <Initiator>
    #          <DisplayName>string</DisplayName>
    #          <ID>string</ID>
    #       </Initiator>
    #       <Key>string</Key>
    #       <Owner>
    #          <DisplayName>string</DisplayName>
    #          <ID>string</ID>
    #       </Owner>
    #       <StorageClass>string</StorageClass>
    #       <UploadId>string</UploadId>
    #    </Upload>
    #    ...
    #    <CommonPrefixes>
    #       <Prefix>string</Prefix>
    #    </CommonPrefixes>
    #    ...
    #    <EncodingType>string</EncodingType>
    # </ListMultipartUploadsResult>

    # example request
    # GET /?uploads&max-uploads=3 HTTP/1.1
    # Host: example-bucket.s3.<Region>.amazonaws.com
    # Date: Mon, 1 Nov 2010 20:34:56 GMT
    # Authorization: authorization string

    # example response
    # HTTP/1.1 200 OK
    # x-amz-id-2: Uuag1LuByRx9e6j5Onimru9pO4ZVKnJ2Qz7/C1NPcfTWAtRPfTaOFg==
    # x-amz-request-id: 656c76696e6727732072657175657374
    # Date: Mon, 1 Nov 2010 20:34:56 GMT
    # Content-Length: 1330
    # Connection: keep-alive
    # Server: AmazonS3

    # <?xml version="1.0" encoding="UTF-8"?>
    # <ListMultipartUploadsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    #   <Bucket>bucket</Bucket>
    #   <KeyMarker></KeyMarker>
    #   <UploadIdMarker></UploadIdMarker>
    #   <NextKeyMarker>my-movie.m2ts</NextKeyMarker>
    #   <NextUploadIdMarker>YW55IGlkZWEgd2h5IGVsdmluZydzIHVwbG9hZCBmYWlsZWQ</NextUploadIdMarker>
    #   <MaxUploads>3</MaxUploads>
    #   <IsTruncated>true</IsTruncated>
    #   <Upload>
    #     <Key>my-divisor</Key>
    #     <UploadId>XMgbGlrZSBlbHZpbmcncyBub3QgaGF2aW5nIG11Y2ggbHVjaw</UploadId>
    #     <Initiator>
    #       <ID>arn:aws:iam::111122223333:user/user1-11111a31-17b5-4fb7-9df5-b111111f13de</ID>
    #       <DisplayName>user1-11111a31-17b5-4fb7-9df5-b111111f13de</DisplayName>
    #     </Initiator>
    #     <Owner>
    #       <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
    #       <DisplayName>OwnerDisplayName</DisplayName>
    #     </Owner>
    #     <StorageClass>STANDARD</StorageClass>
    #     <Initiated>2010-11-10T20:48:33.000Z</Initiated>  
    #   </Upload>
    #   <Upload>
    #     <Key>my-movie.m2ts</Key>
    #     <UploadId>VXBsb2FkIElEIGZvciBlbHZpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA</UploadId>
    #     <Initiator>
    #       <ID>b1d16700c70b0b05597d7acd6a3f92be</ID>
    #       <DisplayName>InitiatorDisplayName</DisplayName>
    #     </Initiator>
    #     <Owner>
    #       <ID>b1d16700c70b0b05597d7acd6a3f92be</ID>
    #       <DisplayName>OwnerDisplayName</DisplayName>
    #     </Owner>
    #     <StorageClass>STANDARD</StorageClass>
    #     <Initiated>2010-11-10T20:48:33.000Z</Initiated>
    #   </Upload>
    #   <Upload>
    #     <Key>my-movie.m2ts</Key>
    #     <UploadId>YW55IGlkZWEgd2h5IGVsdmluZydzIHVwbG9hZCBmYWlsZWQ</UploadId>
    #     <Initiator>
    #       <ID>arn:aws:iam::444455556666:user/user1-22222a31-17b5-4fb7-9df5-b222222f13de</ID>
    #       <DisplayName>user1-22222a31-17b5-4fb7-9df5-b222222f13de</DisplayName>
    #     </Initiator>
    #     <Owner>
    #       <ID>b1d16700c70b0b05597d7acd6a3f92be</ID>
    #       <DisplayName>OwnerDisplayName</DisplayName>
    #     </Owner>
    #     <StorageClass>STANDARD</StorageClass>
    #     <Initiated>2010-11-10T20:49:33.000Z</Initiated>
    #   </Upload>
    # </ListMultipartUploadsResult>
    

    # GET /?uploads&delimiter=Delimiter&encoding-type=EncodingType&key-marker=KeyMarker&max-uploads=MaxUploads&prefix=Prefix&upload-id-marker=UploadIdMarker HTTP/1.1
    let url = &"/?uploads&delimeter{args.delimeter}&encoding-type{args.encoding_type}&key-marker{args.key_marker}&max-uploads{args.max_uploads}&prefix{args.prefix}&upload-id-marker{args.upload_id_marker}";
    let httpMethod = HttpGet
    # let authorization = createAuth(creds, url, httpMethod)
    let headers = newHttpHeaders()

    let res = await client.request(httpMethod=httpMethod, url=url, headers = headers, body = "")
    let body = await res.body
    if res.code != Http200:
        raise newException(HttpRequestError, "Error: " & $res.code & " " & await res.body)
    
    # result = body.parseXml[ListMultipartUploadsResult]()
