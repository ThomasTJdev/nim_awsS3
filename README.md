# awsS3
Amazon Simple Storage Service (AWS S3) basic API support.

If you need more API's then take a look at [atoz](https://github.com/disruptek/atoz).


## Procedures

The core AWS commands has two procedures - one is the raw request returning
the response, the other one is a sugar returning a `assert [is is2xx] == true`.

The raw request commands can be chained where the `client` can be reused,
e.g. the `move to trash`, which consists of a `copyObject` and a `deleteObject`.

All requests are performed async.


Limitations:
Spaces in `keys` is not supported.


## TODO:
- all `bucketHost` should be `bucketName`, and when needed as a host, the
region (host) should be appended within here. In that way we would only
need to pass `bucketName` (shortform) around.


# Example

```nim
import
  std/asyncdispatch,
  std/httpclient,
  std/os

import
  awsS3,
  awsSTS

const
  bucketHost    = "my-bucket.s3-eu-west-1.amazonaws.com"
  bucketName    = "my-bucket"
  serverRegion  = "eu-west-1"
  myAccessKey   = "AKIAEXAMPLE"
  mySecretKey   = "J98765RFGBNYT4567EXAMPLE"
  role          = "arn:aws:iam::2345676543:role/Role-S3-yeah"
  s3File        = "test/test.jpg"
  s3MoveTo      = "test2/test.jpg"
  localTestFile = "/home/username/download/myimage.jpg"
  downloadTo    = "/home/username/git/nim_awsS3/test3.jpg"


## Get creds with awsSTS package
let creds = awsCredentialGet(myAccessKey, mySecretKey, role, serverRegion)

## 1) Create test file
writeFile(localTestFile, "blabla")

## 2) Put object
echo waitFor s3PutObjectIs2xx(creds, bucketHost, s3File, localTestFile)

## 3) Move object
waitFor s3MoveObject(creds, bucketHost, s3MoveTo, bucketHost, bucketName, s3File)

## 4) Get content-length
var client = newAsyncHttpClient()
let m1 = waitFor s3HeadObject(client, creds, bucketHost, s3MoveTo)
echo m1.headers["content-length"]

## 5) Get object
echo waitFor s3GetObjectIs2xx(creds, bucketHost, s3MoveTo, downloadTo)
echo fileExists(downloadTo)

## 6) Delete object
echo waitFor s3DeleteObjectIs2xx(creds, bucketHost, s3MoveTo)
```



# Procs

## s3Creds*

```nim
proc s3Creds*(accessKey, secretKey, tokenKey, region: string): AwsCreds =
```

This uses the nimble package `awsSTS` to store the credentials.


____

## s3Presigned*

Generate S3 presigned URL's.

### API

This is the standard public API.

```nim
proc s3Presigned*(accessKey, secretKey, region: string, bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition = CDTattachment, contentDispositionName = "",
    setContentType = true, fileExt = "", expireInSec = "65", accessToken = ""
  ): string =
```

```nim
proc s3Presigned*(creds: AwsCreds, bucketHost, key: string,
    contentDisposition = CDTattachment, contentDispositionName = "",
    setContentType = true, fileExt = "", expireInSec = "65"
  ): string =
```

### Raw

This exposes the internal API. It has been made public for users to skip the `s3Presigned*`.

```nim
proc s3SignedUrl*(
    credsAccessKey, credsSecretKey, credsRegion: string,
    bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition = CDTignore, contentDispositionName = "",
    setContentType = true,
    fileExt = "", customQuery = "", copyObject = "", expireInSec = "65",
    accessToken = ""
  ): string =

  ## customQuery:
  ##  This is a custom defined header query. The string needs to include the format
  ##  "head1:value,head2:value" - a comma separated string with header and
  ##  value diveded by colon.
  ##
  ## copyObject:
  ##   Attach copyObject to headers
```

### Details
Generates a S3 presigned url for sharing.

```
contentDisposition => sets "Content-Disposition" type (inline/attachment)
contentDispositionName => sets "Content-Disposition" name
setContentType => sets "response-content-type"
fileExt        => only if setContentType=true
                  if `fileExt = ""` then mimetype is automated
                  needs to be ".jpg" (dot before) like splitFile(f).ext
```


### Content-Disposition type

```nim
type
  contentDisposition* = enum
    CDTinline     # Content-Disposition: inline
    CDTattachment # Content-Disposition: attachment
    CDTignore
```


____

## parseReponse*

```nim
proc parseReponse*(response: AsyncResponse): (bool, HttpHeaders) =
```

Helper-Procedure that can be used to return true on success and the response headers.


____

## isSuccess2xx*

```nim
proc isSuccess2xx*(response: AsyncResponse): (bool) =
```

Helper-Procedure that can be used with the raw call for parsing the response.


____

## s3DeleteObject

```nim
proc s3DeleteObject(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key: string): Future[AsyncResponse] {.async.} =
```

AWS S3 API - DeleteObject


____

## s3DeleteObjectIs2xx*

```nim
proc s3DeleteObjectIs2xx*(creds: AwsCreds, bucketHost, key: string): Future[bool] {.async.} =
```

AWS S3 API - DeleteObject bool


____

## s3HeadObject*

```nim
proc s3HeadObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key: string): Future[AsyncResponse] {.async.} =
```

AWS S3 API - HeadObject

 Response: - result.headers["content-length"]


____

## s3HeadObjectIs2xx*

```nim
proc s3HeadObjectIs2xx*(creds: AwsCreds, bucketHost, key: string): Future[bool] {.async.} =
```

AWS S3 API - HeadObject bool

 AWS S3 API - HeadObject is2xx is only checking the existing of the file. If the data is needed, then use the raw `s3HeadObject` procedure and parse the response.


____

## s3GetObject*

```nim
proc s3GetObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, downloadPath: string) {.async.} =
```

AWS S3 API - GetObject

 `downloadPath` needs to full local path.


____

## s3GetObjectIs2xx*

```nim
proc s3GetObjectIs2xx*(creds: AwsCreds, bucketHost, key, downloadPath: string): Future[bool] {.async.} =
```

AWS S3 API - GetObject bool

 AWS S3 API - GetObject is2xx returns true on downloaded file.

 `downloadPath` needs to full local path.


____

## s3PutObject*

```nim
proc s3PutObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, localPath: string): Future[AsyncResponse]  {.async.} =
```

AWS S3 API - PutObject

The PutObject reads the file to memory and uploads it.


____

## s3PutObjectIs2xx*

```nim
proc s3PutObjectIs2xx*(creds: AwsCreds, bucketHost, key, localPath: string, deleteLocalFileAfter=true): Future[bool] {.async.} =
```

AWS S3 API - PutObject bool

This performs a PUT and uploads the file. The `localPath` param needs to be the full path.

The PutObject reads the file to memory and uploads it.

____

## s3CopyObject*

```nim
proc s3CopyObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, copyObject: string): Future[AsyncResponse]  {.async.} =
```

AWS S3 API - CopyObject

The copyObject param is the full path to the copy source, this means both the bucket and file, e.g.:
```
- /bucket-name/folder1/folder2/s3C3FiLXRsPXeE9TUjZGEP3RYvczCFYg.jpg
- /[BUCKET]/[KEY]
```

**TODO:**
Implement error checker. An error occured during `copyObject` can return a 200-response. If the error occurs during the copy operation, the error response is embedded in the 200 OK response. This means that a 200 OK response can contain either a success or an error. (https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html)


____

## s3CopyObjectIs2xx*

```nim
proc s3CopyObjectIs2xx*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, copyObject: string): Future[bool] {.async.} =
```

AWS S3 API - CopyObject bool


____

## s3MoveObject*

```nim
proc s3MoveObject*(creds: AwsCreds, bucketToHost, keyTo, bucketFromHost, bucketFromName, keyFrom: string) {.async.} =
```

This does a pseudo move of an object. We copy the object to the destination and then we delete the object from the original location.

```
bucketToHost   => Destination bucket host
keyTo          => 12/files/file.jpg
bucketFromHost => Origin bucket host
bucketFromName => Origin bucket name
keyFrom        => 24/files/old.jpg
```


____

## s3MoveObjects*

```nim
proc s3MoveObjects*(creds: AwsCreds, bucketHost, bucketFromHost, bucketFromName: string, keys: seq[string], waitValidate = 0, waitDelete = 0) {.async.} =
```

In this (plural) multiple moves are performed. The keys are identical in "from" and "to", so origin and destination are the same.

The `waitValidate` and `waitDelete` are used to wait between the validation if the file exists and delete operation.


____

## s3TrashObject*

```nim
proc s3TrashObject*(creds: AwsCreds, bucketTrashHost, bucketFromHost, bucketFromName, keyFrom: string) {.async.} =
```

This does a pseudo move of an object. We copy the object to the destination and then we delete the object from the original location. The destination in this particular situation - is our trash.

______


# S3 Multipart uploads

To use multipart import it with:

```nim
import awsS3/multipart
```

The upload part in ```src/multipart/api/uploadPart.nim``` contains a full example of
- abortMultipartUpload
- listMultipartUpload
- listParts
- completeMultipartUpload
- createMultipartUpload

## Quick test

The multipart files contains `when isMainModule` which can be used to test the upload
procedures.

To test the full upload procedure: Create a file called testFile.bin with
+10MB of data, copy `example.env` to `.env`, run `nimble install dotenv`
and then run the following command:

```nim
nim c -d:dev -r src/multipart/api/uploadPart.nim
```
____

## abordMultipartUpload

```nim
let abortMultipartUploadRequest = AbortMultipartUploadRequest(
  bucket: bucket,
  key: upload.key,
  uploadId: upload.uploadId.get()
)

try:
    var abortClient = newAsyncHttpClient()
    let abortMultipartUploadResult = await abortClient.abortMultipartUpload(credentials=credentials, bucket=bucket, region=region, args=abortMultipartUploadRequest)
    echo abortMultipartUploadResult.toJson().parseJson().pretty()
except:
    echo getCurrentExceptionMsg()

```

____

## createMultipartUpload

```nim
# initiate the multipart upload
let createMultiPartUploadRequest = CreateMultipartUploadRequest(
    bucket: bucket,
    key: key,
  )

let createMultiPartUploadResult = await client.createMultipartUpload(
        credentials = credentials,
        bucket = bucket,
        region = region,
        args = createMultiPartUploadRequest
  )
```

____

## completeMultipartUpload

```nim
let args = CompleteMultipartUploadRequest(
    bucket: bucket,
    key: key,
    uploadId: uploadId
)

let res = await client.completeMultipartUpload(credentials=credentials, bucket=bucket, region=region, args=args)
echo res.toJson().parseJson().pretty()

```

____

## uploadPart

```nim
let uploadPartCommandRequest = UploadPartCommandRequest(
    bucket: bucket,
    key: key,
    body: body,
    partNumber: partNumber,
    uploadId: createMultiPartUploadResult.uploadId
)
let res = await client.uploadPart(
  credentials = credentials,
  bucket = bucket,
  region = region,
  args = uploadPartCommandRequest
)
echo "\n> uploadPart"
echo res.toJson().parseJson().pretty()
```
____

## listMultipartUploads

```nim
let listMultipartUploadsRequest = ListMultipartUploadsRequest(
    bucket: bucket,
    prefix: some("test")
)
let listMultipartUploadsRes = await client.listMultipartUploads(credentials=credentials, bucket=bucket, region=region, args=listMultipartUploadsRequest)

```

____

## listParts

```nim
let args = ListPartsRequest(
    bucket: bucket,
    key: some(key),
    uploadId: some(uploadId)
)
let result = await client.listParts(credentials=credentials, bucket=bucket, region=region, args=args)
# echo result
echo result.toJson().parseJson().pretty()
```

____
