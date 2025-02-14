import
  std/[
    httpclient,
    os,
    times
  ]

import
  src/awsS3/signed,
  src/awsS3/api,
  src/awsS3/utils_sync,
  awsSTS

const
  bucketHost    = "<BUCKET>.s3-eu-west-1.amazonaws.com"
  bucketName    = "<BUCKET>"
  serverRegion  = "eu-west-1"
  myAccessKey   = "<AKIA...>"
  mySecretKey   = "<SECRET>"
  role          = "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE>"
  s3File1       = "test/test1.jpg"
  s3File2       = "test/test2.jpg"
  s3MoveTo      = "test2/test.jpg"
  localTestFile1 = "/home/user/downloads/myimage1.jpg"
  localTestFile2 = "/home/user/downloads/myimage2.jpg"
  # downloadTo    = "/home/username/git/nim_awsS3/test3.jpg"

## Get creds with awsSTS package
let creds = awsSTScreate(myAccessKey, mySecretKey, serverRegion, role)

# Tests
# ## Move object
# waitFor s3MoveObject(creds, bucketHost, s3MoveTo, bucketHost, bucketName, s3File)

# ## Get content-length
# var client = newAsyncHttpClient()
# let m1 = waitFor s3HeadObject(client, creds, bucketHost, s3MoveTo)
# echo m1.headers["content-length"]

# ## Get object
# echo waitFor s3GetObjectIs2xx(creds, bucketHost, s3MoveTo, downloadTo)
# echo fileExists(downloadTo)

# ## Delete object
# echo waitFor s3DeleteObjectIs2xx(creds, bucketHost, s3MoveTo)



proc upload() =

  ## 1) Create test file
  writeFile(localTestFile1, "blabla")
  writeFile(localTestFile2, "lkjhgfdedrtyuio")

  ## 2) Put object
  echo s3PutObjectIs2xx(creds, bucketHost, s3File1, localTestFile1)
  echo s3PutObjectIs2xx(creds, bucketHost, s3File2, localTestFile2)

proc delete() =
  s3TrashObjects(
    creds,
    "<BUCKET>.s3-eu-west-1.amazonaws.com",
    bucketHost,
    bucketName,
    @[s3File1, s3File2],
    waitValidate = 2000,
    waitDelete = 2000
  )

# upload()
# delete()

let
  tBucket = "<BUCKET>.s3-eu-west-1.amazonaws.com"
  tKey = "<PATH>/<FILE>"

echo s3SignedUrl(
    creds.AWS_ACCESS_KEY_ID, creds.AWS_SECRET_ACCESS_KEY, creds.AWS_REGION,
    tBucket, tKey,
    httpMethod = HttpGet,
    contentDisposition = CDTattachment, contentDispositionName = "",
    setContentType = true, fileExt = "", expireInSec = "6500",
    accessToken = creds.AWS_SESSION_TOKEN,
    makeDateTime = $(getTime().utc.format(basicISO8601))
)




proc move() =
  s3MoveObject(
          creds,
          "<BUCKET>.s3-eu-west-1.amazonaws.com",
          "ulla/dulle",
          "<BUCKET>.s3-eu-west-1.amazonaws.com", "<BUCKET>",
          "test/sub")

# move()



# Delete folder
proc deleteFolder() =
  let client = newHttpClient()
  let result = (s3DeleteObject(client, creds, "<BUCKET>.s3-eu-west-1.amazonaws.com", "test/sub/"))
  echo result.body
  echo result.status
  client.close()

#deleteFolder()