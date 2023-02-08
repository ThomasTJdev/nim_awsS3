import 
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options


import
    ../models/models,
    awsSTS

proc abortMultipartUpload*(client: AsyncHttpClient, creds: AwsCreds, args: AbortMultipartUploadRequest): Future[void] {.async.}  =
    # request 

    # DELETE /Key+?uploadId=UploadId HTTP/1.1
    # Host: Bucket.s3.amazonaws.com
    # x-amz-request-payer: RequestPayer
    # x-amz-expected-bucket-owner: ExpectedBucketOwner

    # response

    # HTTP/1.1 204
    # x-amz-request-charged: RequestCharged

    # example request

    # DELETE /example-object?
    # uploadId=VXBsb2FkIElEIGZvciBlbHZpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZ HTTP/1.1
    # Host: example-bucket.s3.<Region>.amazonaws.com
    # Date: Mon, 1 Nov 2010 20:34:56 GMT
    # Authorization: authorization string 

    # example response

    # HTTP/1.1 204 OK
    # x-amz-id-2: Weag1LuByRx9e6j5Onimru9pO4ZVKnJ2Qz7/C1NPcfTWAtRPfTaOFg==
    # x-amz-request-id: 996c76696e6727732072657175657374
    # Date: Mon, 1 Nov 2010 20:34:56 GMT
    # Content-Length: 0
    # Connection: keep-alive
    # Server: AmazonS3 

    if args.requestPayer.isSome():
        let requestPayer = args.requestPayer.get()
        client.headers.add("x-amz-request-payer", requestPayer)


    let url = &"{endpoint}/{args.key}?uploadId={args.uploadId}"
    let httpMethod = HttpDelete
    # let authorization = createAuthorizationHeader(
    #     creds = creds,
    #     httpMethod = HttpDelete,
    #     url = url,
    #     headers = client.headers
    # )
    
    let res = await client.request(
        httpMethod = httpMethod,
        url = url
    )
    if res.code != Http204:
        raise newException(HttpRequestError, "Error: AbortMultipartUpload failed with code: " & $res.code)
