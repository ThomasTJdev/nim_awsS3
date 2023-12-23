# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

import
  std/httpclient,
  std/os,
  std/logging,
  std/strutils

import
  awsSTS

import
  ./api


#
# Helper procedures
#
proc parseReponse*(response: Response): (bool, HttpHeaders) =
  ## Helper-Procedure that can be used to return true on success and the response
  ## headers.
  if response.code.is2xx:
    when defined(dev): echo "success: " & $response.code
    return (true, response.headers)

  else:
    when defined(dev): echo "failure: " & $response.code
    return (false, response.headers)


proc isSuccess2xx*(response: Response): (bool) =
  ## Helper-Procedure that can be used with the raw call for parsing the response.
  if response.code.is2xx:
    when defined(dev): echo "success: " & $response.code
    return (true)

  else:
    when defined(dev): echo "failure: " & $response.code
    return (false)


proc s3DeleteObjectIs2xx*(creds: AwsCreds, bucketHost, key: string): bool =
  ## AWS S3 API - DeleteObject bool
  if key.contains(" "):
    warn("s3DeleteObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newHttpClient()
    result = (s3DeleteObject(client, creds, bucketHost, key)).isSuccess2xx()
    client.close()


proc s3HeadObjectIs2xx*(creds: AwsCreds, bucketHost, key: string): bool =
  ## AWS S3 API - HeadObject bool
  ##
  ## AWS S3 API - HeadObject is2xx is only checking the existing of the file.
  ## If the data is needed, then use the raw `s3HeadObject` procedure and
  ## parse the response.
  if key.contains(" "):
    warn("s3HeadObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newHttpClient()
    result = (s3HeadObject(client, creds, bucketHost, key)).isSuccess2xx()
    client.close()


proc s3GetObjectIs2xx*(creds: AwsCreds, bucketHost, key, downloadPath: string): bool =
  ## AWS S3 API - GetObject bool
  ##
  ## AWS S3 API - GetObject is2xx returns true on downloaded file.
  ##
  ## `downloadPath` needs to full local path.
  if key.contains(" "):
    warn("s3GetObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    # let client = newHttpClient()
    let client = newHttpClient()
    s3GetObject(client, creds, bucketHost, key, downloadPath)
    client.close()
    result = fileExists(downloadPath)



proc s3PutObjectIs2xx*(creds: AwsCreds, bucketHost, key, localPath: string, deleteLocalFileAfter=true): bool =
  ## AWS S3 API - PutObject bool
  ##
  ## This performs a PUT and uploads the file. The `localPath` param needs to
  ## be the full path.
  ##
  ## The PutObject reads the file to memory and uploads it.
  if not fileExists(localPath):
    return false

  if key.contains(" "):
    warn("s3PutObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newHttpClient()
    result = (s3PutObject(client, creds, bucketHost, key, localPath)).isSuccess2xx()
    client.close()
    if deleteLocalFileAfter:
      removeFile(localPath)


proc s3CopyObjectIs2xx*(creds: AwsCreds, bucketHost, key, copyObject: string): bool =
  ## AWS S3 API - CopyObject bool
  if key.contains(" "):
    warn("s3CopyObjectIs2xx(): Skipping due spaces = " & key)
    return false
  else:
    let client = newHttpClient()
    result = s3CopyObject(client, creds, bucketHost, key, copyObject).isSuccess2xx()
    client.close()


proc s3MoveObject*(creds: AwsCreds, bucketToHost, keyTo, bucketFromHost, bucketFromName, keyFrom: string) =
  ## This does a pseudo move of an object. We copy the object to the destination
  ## and then we delete the object from the original location.
  ##
  ## bucketToHost   => Destination bucket host
  ## keyTo          => 12/files/file.jpg
  ## bucketFromHost => Origin bucket host
  ## bucketFromName => Origin bucket name
  ## keyFrom        => 24/files/old.jpg
  ##
  let client = newHttpClient()

  if s3CopyObject(client, creds, bucketToHost, keyTo, "/" & bucketFromName & "/" & keyFrom).isSuccess2xx():
    if not (s3DeleteObject(client, creds, bucketFromHost, keyFrom)).isSuccess2xx():
      warn("s3MoveObject(): Failed on delete - " & bucketFromHost & keyFrom)

  client.close()


proc s3MoveObjects*(
    creds: AwsCreds,
    bucketHost, bucketFromHost, bucketFromName: string,
    keys: seq[string],
    waitValidate = 0,
    waitDelete = 0
  ) =
  ## In this (plural) multiple moves are performed. The keys are identical in
  ## "from" and "to", so origin and destination are the same.
  ##
  ## The `waitValidate` and `waitDelete` are used to wait between the validation
  ## if the file exists and delete operation.
  let client = newHttpClient()

  var keysSuccess: seq[string]

  for key in keys:
    try:
      if s3CopyObject(client, creds, bucketHost, key, "/" & bucketFromName & "/" & key).isSuccess2xx():
        keysSuccess.add(key)
    except:
      error("s3MoveObjects(): Failed on copy - " & bucketHost & " - " & key)

    if waitValidate > 0:
      sleep(waitValidate)

  for key in keysSuccess:
    try:
      if not (s3DeleteObject(client, creds, bucketFromHost, key)).isSuccess2xx():
        warn("s3MoveObject(): Could not delete - " & bucketFromHost & " - " & key)
    except:
      error("s3MoveObjects(): Failed on delete - " & bucketFromHost & " - " & key)

    if waitDelete > 0:
      sleep(waitDelete)

  client.close()


proc s3TrashObject*(creds: AwsCreds, bucketTrashHost, bucketFromHost, bucketFromName, keyFrom: string) =
  ## This does a pseudo move of an object. We copy the object to the destination
  ## and then we delete the object from the original location.
  ## The destination in this particular situation - is our trash.
  s3MoveObject(creds, bucketTrashHost, keyFrom, bucketFromHost, bucketFromName, keyFrom)


proc s3TrashObjects*(
    creds: AwsCreds,
    bucketTrashHost, bucketFromHost, bucketFromName: string,
    keys: seq[string],
    waitValidate = 0,
    waitDelete = 0
  ) =
  ## This does a pseudo move of an object. We copy the object to the destination
  ## and then we delete the object from the original location.
  ## The destination in this particular situation - is our trash.
  ##
  ## The `waitValidate` is the time to wait between validating the existence of
  ## the file. The `waitDelete` is the time to wait between deleting the files.
  s3MoveObjects(creds, bucketTrashHost, bucketFromHost, bucketFromName, keys, waitValidate, waitDelete)

