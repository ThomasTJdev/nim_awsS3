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
  std/asyncdispatch,
  std/httpclient,
  std/httpcore,
  std/logging,
  std/os,
  std/strutils,
  std/uri

import
  awsSTS

import
  ./signed
export
  signed



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
# S3 presigned GET
#
proc s3Presigned*(accessKey, secretKey, region: string, bucketHost, key: string,
    httpMethod = HttpGet,
    contentDisposition = CDTattachment, contentDispositionName = "",
    setContentType = true, fileExt = "", expireInSec = "65", accessToken = ""
  ): string =
  ## Generates a S3 presigned url for sharing.
  ##
  ## contentDisposition => sets "Content-Disposition" type (inline/attachment)
  ## contentDispositionName => sets "Content-Disposition" name
  ## setContentType => sets "Content-Type"
  ## fileExt        => only if setContentType=true
  ##                   if `fileExt = ""` then mimetype is automated
  ##                   needs to be ".jpg" (dot before) like splitFile(f).ext
  return s3SignedUrl(accessKey, secretKey, region, bucketHost, key,
      httpMethod = httpMethod,
      contentDisposition = contentDisposition, contentDispositionName = contentDispositionName,
      setContentType = setContentType,
      fileExt = fileExt, expireInSec = expireInSec, accessToken = accessToken
    )


proc s3Presigned*(creds: AwsCreds, bucketHost, key: string,
    contentDisposition = CDTattachment, contentDispositionName="",
    setContentType=true, fileExt="", expireInSec="65"): string =

  return s3Presigned(
      creds.AWS_ACCESS_KEY_ID, creds.AWS_SECRET_ACCESS_KEY, creds.AWS_REGION,
      bucketHost, key,
      httpMethod = HttpGet,
      contentDisposition = contentDisposition, contentDispositionName = contentDispositionName,
      setContentType = setContentType, fileExt = fileExt, expireInSec = expireInSec,
      accessToken = creds.AWS_SESSION_TOKEN
    )


#
# Helper procedures
#
proc parseReponse*(response: AsyncResponse): (bool, HttpHeaders) =
  ## Helper-Procedure that can be used to return true on success and the response
  ## headers.
  if response.code.is2xx:
    when defined(dev): echo "success: " & $response.code
    return (true, response.headers)

  else:
    when defined(dev): echo "failure: " & $response.code
    return (false, response.headers)



proc isSuccess2xx*(response: AsyncResponse): (bool) =
  ## Helper-Procedure that can be used with the raw call for parsing the response.
  if response.code.is2xx:
    when defined(dev): echo "success: " & $response.code
    return (true)

  else:
    when defined(dev): echo "failure: " & $response.code
    return (false)




#
# Delete object
#
proc s3DeleteObject(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key: string): Future[AsyncResponse] {.async.} =# Future[tuple[success: bool, headers: HttpHeaders]] {.async.} =
  ## AWS S3 API - DeleteObject
  result = await client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpDelete, setContentType=false), httpMethod=HttpDelete)


proc s3DeleteObjectIs2xx*(creds: AwsCreds, bucketHost, key: string): Future[bool] {.async.} =
  ## AWS S3 API - DeleteObject bool
  if key.contains(" "):
    echo("s3DeleteObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newAsyncHttpClient()
    result = (await (s3DeleteObject(client, creds, bucketHost, key))).isSuccess2xx()
    client.close()




#
# Head object
#
proc s3HeadObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key: string): Future[AsyncResponse] {.async.} =
  ## AWS S3 API - HeadObject
  ##
  ## Response:
  ##  - result.headers["content-length"]
  result = await client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpHead, setContentType=false), httpMethod=HttpHead)


proc s3HeadObjectIs2xx*(creds: AwsCreds, bucketHost, key: string): Future[bool] {.async.} =
  ## AWS S3 API - HeadObject bool
  ##
  ## AWS S3 API - HeadObject is2xx is only checking the existing of the file.
  ## If the data is needed, then use the raw `s3HeadObject` procedure and
  ## parse the response.
  if key.contains(" "):
    echo("s3HeadObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newAsyncHttpClient()
    result = (await (s3HeadObject(client, creds, bucketHost, key))).isSuccess2xx()
    client.close()



#
# Get object
#
# proc s3GetObject*(client: HttpClient, bucketHost, key, downloadPath: string) =
proc s3GetObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, downloadPath: string) {.async.} =
  ## AWS S3 API - GetObject
  ##
  ## `downloadPath` needs to full local path.
  await client.downloadFile(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpGet, setContentType=false), downloadPath)


proc s3GetObjectIs2xx*(creds: AwsCreds, bucketHost, key, downloadPath: string): Future[bool] {.async.} =
  ## AWS S3 API - GetObject bool
  ##
  ## AWS S3 API - GetObject is2xx returns true on downloaded file.
  ##
  ## `downloadPath` needs to full local path.
  if key.contains(" "):
    echo("s3GetObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    # let client = newHttpClient()
    let client = newAsyncHttpClient()
    await s3GetObject(client, creds, bucketHost, key, downloadPath)
    client.close()
    result = fileExists(downloadPath)



#
# Put object
#
proc s3PutObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, localPath: string): Future[AsyncResponse]  {.async.} =
  ## AWS S3 API - PutObject
  ##
  ## The PutObject reads the file to memory and uploads it.
  result = await client.put(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpPut), body = readFile(localPath))


proc s3PutObjectIs2xx*(creds: AwsCreds, bucketHost, key, localPath: string, deleteLocalFileAfter=true): Future[bool] {.async.} =
  ## AWS S3 API - PutObject bool
  ##
  ## This performs a PUT and uploads the file. The `localPath` param needs to
  ## be the full path.
  ##
  ## The PutObject reads the file to memory and uploads it.
  if not fileExists(localPath):
    return false

  if key.contains(" "):
    echo("s3PutObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newAsyncHttpClient()
    result = (await (s3PutObject(client, creds, bucketHost, key, localPath))).isSuccess2xx()
    client.close()
    if deleteLocalFileAfter:
      removeFile(localPath)



#
# Copy object
#
proc s3CopyObject*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, copyObject: string): Future[AsyncResponse]  {.async.} =
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

  result = await client.request(s3SignedUrl(creds, bucketHost, key, httpMethod=HttpPut, copyObject=copyObjectEncoded), httpMethod=HttpPut, headers=headers)


proc s3CopyObjectIs2xx*(client: AsyncHttpClient, creds: AwsCreds, bucketHost, key, copyObject: string): Future[bool] {.async.} =
  ## AWS S3 API - CopyObject bool
  if key.contains(" "):
    echo("s3CopyObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newAsyncHttpClient()
    result = (await s3CopyObject(client, creds, bucketHost, key, copyObject)).isSuccess2xx()
    client.close()



#
# Move object aka Copy & Delete
#
proc s3MoveObject*(creds: AwsCreds, bucketToHost, keyTo, bucketFromHost, bucketFromName, keyFrom: string) {.async.} =
  ## This does a pseudo move of an object. We copy the object to the destination
  ## and then we delete the object from the original location.
  ##
  ## bucketToHost   => Destination bucket host
  ## keyTo          => 12/files/file.jpg
  ## bucketFromHost => Origin bucket host
  ## bucketFromName => Origin bucket name
  ## keyFrom        => 24/files/old.jpg
  ##
  let client = newAsyncHttpClient()

  if (await s3CopyObject(client, creds, bucketToHost, keyTo, "/" & bucketFromName & "/" & keyFrom)).isSuccess2xx():
    if not (await (s3DeleteObject(client, creds, bucketFromHost, keyFrom))).isSuccess2xx():
      echo("s3MoveObject(): Failed on delete - " & bucketFromHost & keyFrom)

  client.close()


proc s3MoveObjects*(creds: AwsCreds, bucketHost, bucketFromHost, bucketFromName: string, keys: seq[string]) {.async.} =
  ## In this (plural) multiple moves are performed. The keys are identical in
  ## "from" and "to", so origin and destination are the same.
  let client = newAsyncHttpClient()

  var keysSuccess: seq[string]

  for key in keys:
    try:
      if (await s3CopyObject(client, creds, bucketHost, key, "/" & bucketFromName & "/" & key)).isSuccess2xx():
        keysSuccess.add(key)
    except:
      error("s3MoveObjects(): Failed on copy - " & bucketHost & " - " & key)
      continue

  for key in keysSuccess:
    try:
      if not (await (s3DeleteObject(client, creds, bucketFromHost, key))).isSuccess2xx():
        warn("s3MoveObject(): Could not delete - " & bucketFromHost & " - " & key)
    except:
      error("s3MoveObjects(): Failed on delete - " & bucketFromHost & " - " & key)
      continue

  client.close()



#
# Trash object aka move
#
proc s3TrashObject*(creds: AwsCreds, bucketTrashHost, bucketFromHost, bucketFromName, keyFrom: string) {.async.} =
  ## This does a pseudo move of an object. We copy the object to the destination
  ## and then we delete the object from the original location.
  ## The destination in this particular situation - is our trash.
  await s3MoveObject(creds, bucketTrashHost, keyFrom, bucketFromHost, bucketFromName, keyFrom)


proc s3TrashObjects*(creds: AwsCreds, bucketTrashHost, bucketFromHost, bucketFromName: string, keys: seq[string]) {.async.} =
  ## This does a pseudo move of an object. We copy the object to the destination
  ## and then we delete the object from the original location.
  ## The destination in this particular situation - is our trash.
  await s3MoveObjects(creds, bucketTrashHost, bucketFromHost, bucketFromName, keys)