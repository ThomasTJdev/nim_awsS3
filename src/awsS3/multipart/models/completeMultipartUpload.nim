import
    common,
    options


type

    CompletedPart* = object
        ## this file is the type definition for the s3 api was created from the aws docs
        ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
        ##
        ## Entity tag of the uploaded part
        eTag*: Option[string]

        ## A base64-encoded, 32-bit CRC32 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumCRC32*: Option[string]

        ## A base64-encoded, 32-bit CRC32C checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumCRC32C*: Option[string]

        ## A base64-encoded, 32-bit SHA1 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumSHA1*: Option[string]

        ## A base64-encoded, 32-bit SHA256 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumSHA256*: Option[string]

        ## The part number of the uploaded part, restricted to 1-10000
        partNumber*: Option[int]


    CompletedMultipartUpload* = object
        # can result in a 400 error when not provided by the request.
        parts*: Option[seq[CompletedPart]]


    CompleteMultipartUploadRequest* = object

        ## The bucket name of the uploaded the part.
        bucket*: string

        ## Key of the object to upload. AKA the filepath/filename.
        key*: string

        ## The ID that identifies the multipart upload.
        uploadId*: string

        # Multipart upload request body
        multipartUpload*: Option[CompletedMultipartUpload]

        ## A base64-encoded, 32-bit CRC32 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumCRC32*: Option[string]

        ## A base64-encoded, 32-bit CRC32C checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumCRC32C*: Option[string]

        ## A base64-encoded, 32-bit SHA1 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumSHA1*: Option[string]

        ## A base64-encoded, 32-bit SHA256 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumSHA256*: Option[string]

        ## Tag to specify if the Requester Pays Buckets
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html"
        # requestPayer*: Option[RequestPayer | string]
        requestPayer*: Option[string]

        ## ID of the expected bucket owner. If the bucket is owned by a different account the request will fail with error code 403.
        expectedBucketOwner*: Option[string]

        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        sseCustomerAlgorithm*: Option[string]

        # Server-side encryption (SSE) Key used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        sseCustomerKey*: Option[string]

        # Server-side encryption (SSE) MD5 checksum.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        sseCustomerKeyMD5*: Option[string]


    CompleteMultipartUploadResult* = object

        location*: Option[string]

        bucket*: Option[string]

        key*: Option[string]

        expiration*: Option[string]

        eTag*: Option[string]

        checksumCRC32*: Option[string]

        checksumCRC32C*: Option[string]

        checksumSHA1*: Option[string]

        checksumSHA256*: Option[string]

        serverSideEncryption*: Option[ServerSideEncryption]

        versionId*: Option[string]

        sseKMSKeyId*: Option[string]

        bucketKeyEnabled*: Option[bool]

        requestCharged*: Option[string]