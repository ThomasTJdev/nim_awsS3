# v3.0.2

## Changes

* Implementation of synchronous procedures

## Breaking changes

* Refactor folder structure. Split multipart upload into separate area.
* To use multipart upload `import awsS3/multipart`
* `s3CopyObjectIs2xx` has wrong formatting - required client-param but also
  initialized a client.
* All suger procedures, e.g. `is2xx`, has been splitted into separate files
  for async and sync. To use them `import awsS3/utils_async` or
  `import awsS3/utils_sync`



# v3.0.0

## Changes

* Implement support for multipart upload and friends.


# v2.0.1

## Changes

* `try-except` within `moveObjects` on `copyObjects` to prevent error. This is temporary until the `copyObject` proc is fixed according to inline comment.


# v2.0.0

## Breaking changes

API for s3Presigned* and s3SignedUrl* is changed. If you are using the param
`contentName: string` in the s3Presigned* and s3SignedUrl* functions, you need
to update your code to use the new API.

* `contentName` is now `contentDispositionName`
* Content-Disposition is not automatically set to `attachment` if Content-
    Disposition-Name is set. It has to be set manually with `contentDisposition`.
* You can set Constent-Disposition type and name independently with
    `contentDisposition` and `contentDispositionName`

**Old**:
```nim
echo s3Presigned(creds, bucketHost = bucketHostPer, key = "12/files/s3RDRB6II4i9pbswsVppmAreU24nmP1n.pdf", contentName="Filename XX", setContentType=true, fileExt=".pdf", expireInSec="432000")
```

**New**:
```nim
echo s3Presigned(awsCreds, bucketHost = bucketHostPer, key = "12/files/s3RDRB6II4i9pbswsVppmAreU24nmP1n.pdf", contentDisposition = CDTattachment, contentDispositionName="Filename XX", setContentType=true, fileExt=".pdf", expireInSec="432000")

# OR

echo s3Presigned(awsKey, awsSecret, awsRegion, bucketHost = bucketHostPer, key = "12/files/s3RDRB6II4i9pbswsVppmAreU24nmP1n.pdf", contentDisposition = CDTattachment, contentDispositionName="Filename XX", setContentType=true, fileExt=".pdf", expireInSec="432000", accessToken = awsToken)
```


## Changes

* Private s3SignedUrl is not exposed directly.
* Content-Disposition type is set by `contentDisposition* = enum`.
* Content-Disposition name is now included in quotes to allow special characters.
* Both s3Presigned and s3SignedUrl can be called with credentials as string
    instead of using AwsCreds.