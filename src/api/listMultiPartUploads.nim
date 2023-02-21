# std
import
    os,
    httpclient,
    asyncdispatch,
    strutils,
    sequtils,
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

from awsSTS import AwsCreds

proc listMultipartUploads*(
        client: AsyncHttpClient,
        credentials: AwsCreds,
        headers: HttpHeaders = newHttpHeaders(),
        bucket: string,
        region: string,
        service="s3",
        args: ListMultipartUploadsRequest
    ): Future[ListMultipartUploadsResult] {.async.} =
    ## List Multipart Uploads
    ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    ## This operation lists in-progress multipart uploads. An in-progress multipart upload is a multipart upload that has been initiated using the Initiate Multipart Upload request, but has not yet been completed or aborted.

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

    if args.expectedBucketOwner.isSome():
      client.headers["x-amz-expected-bucket-owner"] = args.expectedBucketOwner.get()

    # GET /?uploads=&delimiter=Delimiter&encoding-type=EncodingType&key-marker=KeyMarker&max-uploads=MaxUploads&prefix=Prefix&upload-id-marker=UploadIdMarker HTTP/1.1

    let httpMethod = HttpGet
    let endpoint = &"htts://{bucket}.{service}.{region}.amazonaws.com"
    var url = &"{endpoint}/?uploads="

    if args.delimiter.isSome():
      url = url & "&delimiter=" & args.delimiter.get()
    if args.encodingType.isSome():
      url = url & "&encoding-type=" & args.encodingType.get()
    if args.keyMarker.isSome():
      url = url & "&key-marker=" & args.keyMarker.get()
    if args.maxUploads.isSome():
      url = url & "&max-uploads=" & $args.maxUploads.get()
    if args.prefix.isSome():
      url = url & "&prefix=" & args.prefix.get()
    if args.uploadIdMarker.isSome():
      url = url & "&upload-id-marker=" & args.uploadIdMarker.get()



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
    let jsonStr = json["ListMultipartUploadsResult"].toJson()
    when defined(dev):
      echo "\n> jsonStr: "
      echo jsonStr
    let obj = jsonStr.fromJson(ListMultipartUploadsResult)

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

    let credentials = AwsCreds(AWS_ACCESS_KEY_ID: accessKey, AWS_SECRET_ACCESS_KEY: secretKey)

    var client = newAsyncHttpClient()

    let args = ListMultipartUploadsRequest(
        bucket: bucket,
        prefix: some("test")
    )
    let result = await client.listMultipartUploads(credentials=credentials, bucket=bucket, region=region, args=args)
    echo result.toJson().parseJson().pretty()


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