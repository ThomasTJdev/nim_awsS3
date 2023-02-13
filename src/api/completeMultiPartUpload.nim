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

from awsSTS import AwsCreds


proc makePartsXml(parts: seq[CompletedPart]): string =
    for part in parts:
        result = result & "<Part>"
        if part.checksumCRC32.isSome():
            result = result & &"<ChecksumCRC32>{part.checksumCRC32.get()}</ChecksumCRC32>"
        if part.checksumCRC32C.isSome():
            result = result & &"<ChecksumCRC32C>{part.checksumCRC32C.get()}</ChecksumCRC32C>"
        if part.checksumSHA1.isSome():
            result = result & &"<ChecksumSHA1>{part.checksumSHA1.get()}</ChecksumSHA1>"
        if part.checksumSHA256.isSome():
            result = result & &"<ChecksumSHA256>{part.checksumSHA256.get()}</ChecksumSHA256>"
        if part.eTag.isSome():
            result = result & &"<ETag>{part.eTag.get()}</ETag>"
        if part.partNumber.isSome():
            result = result & &"<PartNumber>{part.partNumber.get()}</PartNumber>"
        result = result & "</Part>"

proc completeMultipartUpload*(
        client: AsyncHttpClient,
        credentials: AwsCreds,
        headers: HttpHeaders = newHttpHeaders(),
        bucket: string,
        region: string,
        service="s3",
        args: CompleteMultipartUploadRequest
    ): Future[CompleteMultipartUploadResult] {.async.}  =
    # The CompleteMultipartUpload operation completes a multipart upload by assembling previously uploaded parts.
    # https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html

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
    # <Part>
    #     <ChecksumCRC32>string</ChecksumCRC32>
    #     <ChecksumCRC32C>string</ChecksumCRC32C>
    #     <ChecksumSHA1>string</ChecksumSHA1>
    #     <ChecksumSHA256>string</ChecksumSHA256>
    #     <ETag>string</ETag>
    #     <PartNumber>integer</PartNumber>
    # </Part>
    # ...
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

    let httpMethod = HttpPost
    let endpoint = &"htts://{bucket}.{service}.{region}.amazonaws.com"
    var url = &"{endpoint}/{args.key}?uploadId={args.uploadId}"

    if args.checksumCRC32.isSome():
        headers["x-amz-checksum-crc32"]        = args.checksumCRC32.get()
    if args.checksumCRC32C.isSome():
        headers["x-amz-checksum-crc32c"]       = args.checksumCRC32C.get()
    if args.checksumSHA1.isSome():
        headers["x-amz-checksum-sha1"]         = args.checksumSHA1.get()
    if args.checksumSHA256.isSome():
        headers["x-amz-checksum-sha256"]       = args.checksumSHA256.get()
    if args.requestPayer.isSome():
        headers["x-amz-request-payer"]         = args.requestPayer.get()
    if args.expectedBucketOwner.isSome():
        headers["x-amz-expected-bucket-owner"] = args.expectedBucketOwner.get()
    if args.sseCustomerAlgorithm.isSome():
        headers["x-amz-server-side-encryption-customer-algorithm"] = args.sseCustomerAlgorithm.get()
    if args.sseCustomerKey.isSome():
        headers["x-amz-server-side-encryption-customer-key"]       = args.sseCustomerKey.get()
    if args.sseCustomerKeyMD5.isSome():
        headers["x-amz-server-side-encryption-customer-key-MD5"]   = args.sseCustomerKeyMD5.get()
    
    var partsXml = ""
    if args.multipartUpload.isSome():
        if args.multipartUpload.get().parts.isSome():
            partsXml = args.multipartUpload.get().parts.get().makePartsXml()

    let payload = &"""<CompleteMultipartUpload xmlns="http://s3.amazonaws.com/doc/2006-03-01/">{partsXml}</CompleteMultipartUpload>"""
    
    when defined(dev):
        echo "\n>completeMultiPart.payload: "
        echo payload

    let res = await client.request(credentials=credentials, headers=headers, httpMethod=httpMethod, url=url, region=region, service=service, payload=payload)
    let body = await res.body

    when defined(dev):
        echo "<url: ", url
        echo "<method: ", httpMethod
        echo "<code: ", res.code
        echo "<headers: ", res.headers
        echo "<body: ", body

    if res.code != Http200:
        raise newException(HttpRequestError, "Error: " & $res.code & " " & await res.body)

    let xml = body.parseXML()
    let json = xml.xml2Json()
    let jsonStr = json["CompleteMultipartUploadResult"].toJson()
    let obj = jsonStr.fromJson(CompleteMultipartUploadResult)

    when defined(dev):
        echo "\n> xml: ", xml
        echo "\n> jsonStr: ", jsonStr
        # echo obj
        # echo "\n> obj string: ", obj.toJson().parseJson().pretty()
    result = obj

    if res.headers.hasKey("x-amz-expiration"):
        result.expiration = some($res.headers["x-amz-expiration"])
    if res.headers.hasKey("x-amz-server-side-encryption"):
        result.serverSideEncryption = some(parseEnum[ServerSideEncryption]($res.headers["x-amz-server-side-encryption"]))
    if res.headers.hasKey("x-amz-version-id"):
        result.versionId = some($res.headers["x-amz-version-id"])
    if res.headers.hasKey("x-amz-server-side-encryption-aws-kms-key-id"):
        result.ssekmsKeyId = some($res.headers["x-amz-server-side-encryption-aws-kms-key-id"])
    if res.headers.hasKey("x-amz-server-side-encryption-bucket-key-enabled"):
        result.bucketKeyEnabled = some(parseBool($res.headers["x-amz-server-side-encryption-bucket-key-enabled"]))
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
        key    = "testFile.bin"

    let credentials = AwsCreds(AWS_ACCESS_KEY_ID: accessKey, AWS_SECRET_ACCESS_KEY: secretKey)

    var client = newAsyncHttpClient()

    let uploadId = ""
    let args = CompleteMultipartUploadRequest(
        bucket: bucket,
        key: key,
        uploadId: uploadId
    )

    let res = await client.completeMultipartUpload(credentials=credentials, bucket=bucket, region=region, args=args)
    echo res.toJson().parseJson().pretty()


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