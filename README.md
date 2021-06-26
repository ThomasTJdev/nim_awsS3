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
  localTestFile = "/home/username/download/myimage.jpg"
  s3MoveTo      = "test2/test.jpg"
  downloadTo    = "/home/username/git/nim_awsS3/test3.jpg"


## Get creds with awsSTS package
let creds = awsCredentialGet(myAccessKey, mySecretKey, role, serverRegion)

## putObject
echo waitFor s3PutObjectIs2xx(creds, bucketHost, "test/test.jpg", localTestFile)

## moveObject (copy and delete)
waitFor s3MoveObject(creds, bucketHost, s3MoveTo, bucketHost, bucketName, "test/test.jpg")

## headObject
var client = newAsyncHttpClient()
let m1 = waitFor s3HeadObject(client, creds, bucketHost, s3MoveTo)
echo m1.headers["content-length"]

## getObject
echo waitFor s3GetObjectIs2xx(creds, bucketHost, s3MoveTo, downloadTo)
echo fileExists(downloadTo)

## deleteObject
echo waitFor s3DeleteObjectIs2xx(creds, bucketHost, s3MoveTo)
```



# Procs

## s3Creds*

```nim
proc s3Creds*(accessKey, secretKey, tokenKey, region: string): AwsCreds =
```

Don't like the `awsSTS` package? Fine, just create the creds here.


____

## s3Presigned*

```nim
proc s3Presigned*(creds: AwsCreds, bucketHost, key: string, contentName="", setContentType=true, fileExt="", expireInSec="65"): string =
```

Generates a S3 presigned url for sharing.

```
contentName    => sets "response-content-disposition" and "attachment"
setContentType => sets "response-content-type"
fileExt        => only if setContentType=true
                  if `fileExt = ""` then mimetype is automated
                  needs to be ".jpg" (dot before) like splitFile(f).ext
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




____

## s3PutObjectIs2xx*

```nim
proc s3PutObjectIs2xx*(creds: AwsCreds, bucketHost, key, localPath: string, deleteLocalFileAfter=true): Future[bool] {.async.} =
```

AWS S3 API - PutObject bool

 This performs a PUT and uploads the file. The `localPath` param needs to be the full path.


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
proc s3MoveObjects*(creds: AwsCreds, bucketHost, bucketFromHost, bucketFromName: string, keys: seq[string]) {.async.} =
```

In this (plural) multiple moves are performed. The keys are identical in "from" and "to", so origin and destination are the same.


____

## s3TrashObject*

```nim
proc s3TrashObject*(creds: AwsCreds, bucketTrashHost, bucketFromHost, bucketFromName, keyFrom: string) {.async.} =
```

This does a pseudo move of an object. We copy the object to the destination and then we delete the object from the original location. The destination in this particular situation - is our trash.


____



**README generated with [nimtomd](https://github.com/ThomasTJdev/nimtomd)**