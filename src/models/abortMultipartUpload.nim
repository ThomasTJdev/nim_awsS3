import 
    common,
    options

# this file is the tyoe definition for the s3 api taken from the aws docs
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html

type
    AbortMultipartUploadRequest* = object

        ## The bucket name upload the part to.
        Bucket*: string

        ## Key of the object to upload. AKA the filepath/filename.
        Key*: string

        ## The ID that identifies the multipart upload
        UploadId*: string

        ## Tag to specify if the Requester Pays Buckets
        ## https*://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html"
        RequestPayer*: Option[RequestPayer | string]

        ## The ID of the expected bucket owner. If the bucket is owned by a different account the request will fail with error code 403.
        ExpectedBucketOwner*: Option[string]