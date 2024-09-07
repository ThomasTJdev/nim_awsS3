# Copyright CxPlanner @ Thomas T. Jarløv (TTJ)
#
## The core AWS commands has two procedures - one is the raw request returning
## the response, the other one is a sugar returning a `assert success (is2xx) == true`.
##
## The raw request commands can be chained where the `client` can be reused,
## e.g. the `move to trash`, which consists of a `copyObject` and a `deleteObject`.
##
## All requests are performed async.
##
## To get data on e.g. `headObject` just parse the headers:
##  - response.headers["content-length"]
##
##
## Limitations:
## Spaces in `keys` is not supported.
##
##
## TODO:
##  - all `bucketHost` should be `bucketName`, and when needed as a host, the
##    region (host) should be appended within here. In that way we would only
##    need to pass `bucketName` (shortform) around.


import
  std/[
    asyncdispatch,
    httpclient,
    httpcore,
    logging,
    os,
    strutils,
    uri
  ]

import
  awsSTS

import
  ./signed




#
# Credentials
#
proc s3Creds*(accessKey, secretKey, tokenKey, region: string): AwsCreds =
  ## Don't like the `awsSTS` package? Fine, just create the creds here.
  result = AwsCreds(
    AWS_REGION:             region,
    AWS_ACCESS_KEY_ID:      accessKey,
    AWS_SECRET_ACCESS_KEY:  secretKey,
    AWS_SESSION_TOKEN:      tokenKey
  )



#
# Delete object
#
proc s3DeleteObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key: string): Future[AsyncResponse] {.async.} =
  ## AWS S3 API - DeleteObject
  result = await client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpDelete, setContentType=false), httpMethod=HttpDelete)


proc s3DeleteObject*(client: HttpClient, creds: AwsCreds, bucketHost, key: string): Response =
  ## AWS S3 API - DeleteObject
  result = client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpDelete, setContentType=false), httpMethod=HttpDelete)




#
# Head object
#
proc s3HeadObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key: string): Future[AsyncResponse] {.async.} =
  ## AWS S3 API - HeadObject
  ##
  ## Response:
  ##  - result.headers["content-length"]
  result = await client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpHead, setContentType=false), httpMethod=HttpHead)


proc s3HeadObject*(client: HttpClient, creds: AwsCreds, bucketHost, key: string): Response =
  ## AWS S3 API - HeadObject
  ##
  ## Response:
  ##  - result.headers["content-length"]
  result = client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpHead, setContentType=false), httpMethod=HttpHead)




#
# Get object
#
proc s3GetObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, downloadPath: string) {.async.} =
  ## AWS S3 API - GetObject
  ##
  ## `downloadPath` needs to full local path.
  await client.downloadFile(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpGet, setContentType=false), downloadPath)


proc s3GetObject*(client: HttpClient, creds: AwsCreds, bucketHost, key, downloadPath: string) =
  ## AWS S3 API - GetObject
  ##
  ## `downloadPath` needs to full local path.
  client.downloadFile(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpGet, setContentType=false), downloadPath)




#
# Put object
#
proc s3PutObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, localPath: string): Future[AsyncResponse]  {.async.} =
  ## AWS S3 API - PutObject
  ##
  ## The PutObject reads the file to memory and uploads it.
  result = await client.put(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpPut), body = readFile(localPath))


proc s3PutObject*(client: HttpClient, creds: AwsCreds, bucketHost, key, localPath: string): Response =
  ## AWS S3 API - PutObject
  ##
  ## The PutObject reads the file to memory and uploads it.
  result = client.put(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpPut), body = readFile(localPath))



#
# Copy object
#
proc s3CopyObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, copyObject: string): Future[AsyncResponse] {.async.} =
  ## AWS S3 API - CopyObject
  ##
  ## The copyObject param is the full path to the copy source, this means both
  ## the bucket and file, e.g.
  ##  - "/bucket-name/folder1/folder2/s3C3FiLXRsPXeE9TUjZGEP3RYvczCFYg.jpg"
  ##  - "/[BUCKET]/[KEY]
  ##
  ## TODO: Implement error checker. An error occured during `copyObject` can
  ##       return a 200-response.
  ##       If the error occurs during the copy operation, the error response is
  ##       embedded in the 200 OK response. This means that a 200 OK response
  ##       can contain either a success or an error.
  ##       (https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html)

  let
    copyObjectEncoded = copyObject.encodeUrl()
    headers = newHttpHeaders(@[
      ("host", bucketHost),
      ("x-amz-copy-source", copyObjectEncoded),
    ])

  result = await client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpPut, copyObject=copyObjectEncoded, setContentType=false), httpMethod=HttpPut, headers=headers)


proc s3CopyObject*(client: HttpClient, creds: AwsCreds, bucketHost, key, copyObject: string): Response =
  ## AWS S3 API - CopyObject
  ##
  ## The copyObject param is the full path to the copy source, this means both
  ## the bucket and file, e.g.
  ##  - "/bucket-name/folder1/folder2/s3C3FiLXRsPXeE9TUjZGEP3RYvczCFYg.jpg"
  ##  - "/[BUCKET]/[KEY]
  ##
  ## TODO: Implement error checker. An error occured during `copyObject` can
  ##       return a 200-response.
  ##       If the error occurs during the copy operation, the error response is
  ##       embedded in the 200 OK response. This means that a 200 OK response
  ##       can contain either a success or an error.
  ##       (https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html)

  let
    copyObjectEncoded = copyObject.encodeUrl()
    headers = newHttpHeaders(@[
      ("host", bucketHost),
      ("x-amz-copy-source", copyObjectEncoded),
    ])

  result = client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpPut, copyObject=copyObjectEncoded, setContentType=false), httpMethod=HttpPut, headers=headers)


