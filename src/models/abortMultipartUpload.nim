import 
    common,
    options

# this file is the tyoe definition for the s3 api taken from the aws docs
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html

type
    AbortMultipartUploadRequest* = object

        ## The bucket name upload the part to.
        bucket*: string

        ## Key of the object to upload. AKA the filepath/filename.
        key*: string

        ## The ID that identifies the multipart upload
        uploadId*: string

        ## Tag to specify if the Requester Pays Buckets
        ## https*://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html"
        # requestPayer*: Option[RequestPayer | string]
        requestPayer*: Option[string]

        ## The ID of the expected bucket owner. If the bucket is owned by a different account the request will fail with error code 403.
        expectedBucketOwner*: Option[string]

    AbortMultipartUploadResult* = object
        ## Tag to specify if the Requester Pays Buckets
        ## https*://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html"
        # requestPayer*: Option[RequestPayer | string]
        requestCharged*: Option[string]