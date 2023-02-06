import
    common,
    options

# this file is the tyoe definition for the s3 api taken from the aws docs
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html

type
    CompletedPart* = object

        ## Entity tag of the uploaded part
        ETag*: Option[string]

        ## A base64-encoded, 32-bit CRC32 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumCRC32*: Option[string]

        ## A base64-encoded, 32-bit CRC32C checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumCRC32C*: Option[string]

        ## A base64-encoded, 32-bit SHA1 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumSHA1*: Option[string]

        ## A base64-encoded, 32-bit SHA256 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumSHA256*: Option[string]

        ## The part number of the uploaded part, restricted to 1-10000
        PartNumber*: Option[int]


    CompletedMultipartUpload* = object
        # can result in a 400 error when not provided by the request.
        Parts*: Option[seq[CompletedPart]]

    CompleteMultipartUploadRequest* = object

        ## The bucket name of the uploaded the part.
        Bucket*: string
        
        ## Key of the object to upload. AKA the filepath/filename.
        Key*: string

        ## The ID that identifies the multipart upload.
        UploadId*: string

        # Multipart upload request body
        MultipartUpload*: Option[CompletedMultipartUpload]

        ## A base64-encoded, 32-bit CRC32 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumCRC32*: Option[string]

        ## A base64-encoded, 32-bit CRC32C checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumCRC32C*: Option[string]

        ## A base64-encoded, 32-bit SHA1 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumSHA1*: Option[string]

        ## A base64-encoded, 32-bit SHA256 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumSHA256*: Option[string]

        ## Tag to specify if the Requester Pays Buckets
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html"
        RequestPayer*: Option[RequestPayer | string]

        ## ID of the expected bucket owner. If the bucket is owned by a different account the request will fail with error code 403.
        ExpectedBucketOwner*: Option[string]

        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerAlgorithm*: Option[string]

        # Server-side encryption (SSE) Key used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerKey*: Option[string]

        # Server-side encryption (SSE) MD5 checksum.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerKeyMD5*: Option[string]
