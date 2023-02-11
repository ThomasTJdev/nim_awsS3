import 
    os,
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options,
    xmlparser,
    xmltree,
    times

import
    ../models/models,
    ../signedv2,
    xml2Json,
    json,
    jsony,
    dotenv,
    utils


proc listParts*(
        client: AsyncHttpClient,
        credentials: AwsCredentials,
        headers: HttpHeaders = newHttpHeaders(),
        bucket: string,
        region: string,
        service="s3",
        args: ListPartsRequest
    ): Future[ListPartsResult] {.async.} =
    ## List Multipart Uploads
    ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    ## This operation lists in-progress multipart uploads. An in-progress multipart upload is a multipart upload that has been initiated using the Initiate Multipart Upload request, but has not yet been completed or aborted.

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
   
    if args.requestPayer.isSome():
        headers["x-amz-request-payer"] = args.requestPayer.get()
    if args.expectedBucketOwner.isSome():
        headers["x-amz-expected-bucket-owner"] = args.expectedBucketOwner.get()
    if args.sseCustomerAlgorithm.isSome():
        headers["x-amz-server-side-encryption-customer-algorithm"] = args.sseCustomerAlgorithm.get()
    if args.sseCustomerKey.isSome():
        headers["x-amz-server-side-encryption-customer-key"] = args.sseCustomerKey.get()
    if args.sseCustomerKeyMD5.isSome():
        headers["x-amz-server-side-encryption-customer-key-MD5"] = args.sseCustomerKeyMD5.get()
    
    # GET /Key+?max-parts=MaxParts&part-number-marker=PartNumberMarker&uploadId=UploadId HTTP/1.1

    let httpMethod = HttpGet
    let endpoint = &"htts://{bucket}.{service}.{region}.amazonaws.com"
    var url = &"{endpoint}/{args.key}?uploadId={args.uploadId}"

    if args.maxParts.isSome():
        url = url & "&max-parts=" & $args.maxParts.get()
    if args.partNumberMarker.isSome():
        url = url & "&part-number-marker=" & $args.partNumberMarker.get()
    
    let res = await client.request(credentials=credentials, headers=headers, httpMethod=httpMethod, url=url, region=region, service=service, payload="")
    let body = await res.body

    when defined(dev):
        echo "\n< listMultipartUploads.url"
        echo url
        echo "\n< listMultipartUploads.method"
        echo httpMethod
        echo "\n< listMultipartUploads.code"
        echo res.code
        echo "\n< listMultipartUploads.headers"
        echo res.headers
        echo "\n< listMultipartUploads.body"
        echo body

    if res.code != Http200:
        raise newException(HttpRequestError, "Error: " & $res.code & " " & await res.body)

    let xml = body.parseXML()
    let json = xml.xml2Json()
    let jsonStr = json.toJson()
    echo jsonStr
    let obj = jsonStr.fromJson(ListPartsResult)

    when defined(dev):
        echo "\n> xml: ", xml
        echo "\n> jsonStr: ", jsonStr
        # echo obj
        # echo "\n> obj string: ", obj.toJson().parseJson().pretty()
    result = obj

    if res.headers.hasKey("x-amz-abort-date"):
      result.abortDate = some(parse($res.headers["x-amz-abort-date"], "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"))
    if res.headers.hasKey("x-amz-abort-rule-id"):
        result.abortRuleId = some($res.headers["x-amz-abort-rule-id"])
    if res.headers.hasKey("x-amz-request-charged"):
        result.requestCharged = some($res.headers["x-amz-request-charged"])
    
    



proc main() {.async.} =
    # load .env environment variables
    load()
    # this is just a scoped testing function
    let
        accessKey = os.getEnv("AWS_ACCESS_KEY_ID")
        secretKey = os.getEnv("AWS_SECRET_ACCESS_KEY")
        region = "eu-west-2"
        bucket = "nim-aws-s3-multipart-upload"

    let credentials = AwsCredentials(id: accessKey, secret: secretKey)

    var client = newAsyncHttpClient()

    let args = ListPartsRequest(
        bucket: bucket,
        prefix: some("test")
    )
    let result = await client.listParts(credentials=credentials, bucket=bucket, region=region, args=args)

    # echo result


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