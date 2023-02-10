import 
    os,
    httpclient,
    asyncdispatch,
    strutils,
    strformat,
    options


import
    ../models/models,
    ../signedv2,
    dotenv

proc abortMultipartUpload*(
        client: AsyncHttpClient,
        credentials: AwsCredentials,
        bucket: string,
        region: string,
        service="s3",
        args: AbortMultipartUploadRequest
    ): Future[void] {.async.}  =
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
    
    let endpoint = &"https://{args.bucket}.s3.{args.region}.amazonaws.com"
    let url = &"{endpoint}/{args.key}?uploadId={args.uploadId}"
    let httpMethod = HttpDelete

    let res = await client.request(credentials, httpMethod, url, region, service, payload="")

    let body = await res.body()

    when defined(dev):
        echo "<url: ", url
        echo "<method: ", httpMethod
        echo "<code: ", res.code
        echo "<headers: ", res.headers
        echo "<body: ", body

    if res.code != Http204:
        raise newException(HttpRequestError, "Error: AbortMultipartUpload failed with code: " & $res.code)
    
proc main() {.async.} =
    # load .env environment variables
    load()
    # this is just a scoped testing function
    let
        accessKey = os.getEnv("AWS_ACCESS_KEY_ID")
        secretKey = os.getEnv("AWS_SECRET_ACCESS_KEY")
        region    = "eu-west-2"
        bucket    = "nim-aws-s3-multipart-upload"
        key       = "testFile.bin"
        uploadId  = ""  

    let credentials = AwsCredentials(id: accessKey, secret: secretKey)

    var client = newAsyncHttpClient()



    let args = AbortMultipartUploadRequest(
        bucket: bucket,
        key: key,
        uploadId: uploadId
    )

    await client.abortMultipartUpload(credentials=credentials, bucket=bucket, region=region, args=args)



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