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
    utils,
    listMultipartUploads

proc abortMultipartUpload*(
        client: AsyncHttpClient,
        credentials: AwsCredentials,
        headers: HttpHeaders = newHttpHeaders(),
        bucket: string,
        region: string,
        service="s3",
        args: AbortMultipartUploadRequest
    ): Future[AbortMultipartUploadResult] {.async.}  =
    ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html

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
        client.headers["x-amz-request-payer"] = args.requestPayer.get()
    if args.expectedBucketOwner.isSome():
        client.headers["x-amz-expected-bucket-owner"] = args.expectedBucketOwner.get()
    
    let httpMethod = HttpDelete
    let endpoint = &"htts://{bucket}.{service}.{region}.amazonaws.com"
    let url = &"{endpoint}/{args.key}?uploadId={args.uploadId}"

    let res = await client.request(credentials=credentials, headers=headers, httpMethod=httpMethod, url=url, region=region, service=service, payload="")
    # let body = await res.body()

    when defined(dev):
        echo "<url: ", url
        echo "<method: ", httpMethod
        echo "<code: ", res.code
        echo "<headers: ", res.headers
        # echo "<body: ", body

    if res.code != Http204:
        raise newException(HttpRequestError, "Error: AbortMultipartUpload failed with code: " & $res.code)

    if res.headers.hasKey("x-amz-request-charged"):
      result.requestCharged = some($res.headers["x-amz-request-charged"])

    
proc main() {.async.} =
    # load .env environment variables
    load()
    # this is just a scoped testing function
    let
        accessKey = os.getEnv("AWS_ACCESS_KEY_ID")
        secretKey = os.getEnv("AWS_SECRET_ACCESS_KEY")
        region    = "eu-west-2"
        bucket    = "nim-aws-s3-multipart-upload"


    let credentials = AwsCredentials(id: accessKey, secret: secretKey)

    var client = newAsyncHttpClient()

    let args = ListMultipartUploadsRequest(
        bucket: bucket,
        prefix: some("test")
    )
    let listMultipartUploadsRes = await client.listMultipartUploads(credentials=credentials, bucket=bucket, region=region, args=args)

    if listMultipartUploadsRes.uploads.isNone():
        echo "No uploads found"
        return

    var uploads = listMultipartUploadsRes.uploads.get()
    echo uploads.len()

    for upload in uploads:
        let args = AbortMultipartUploadRequest(
            bucket: bucket,
            key: upload.key,
            uploadId: upload.uploadId.get()
        )

        try:
          var abortClient = newAsyncHttpClient()
          let abortMultipartUploadResult = await abortClient.abortMultipartUpload(credentials=credentials, bucket=bucket, region=region, args=args)
          echo abortMultipartUploadResult.toJson().parseJson().pretty()
        except:
          echo getCurrentExceptionMsg()


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