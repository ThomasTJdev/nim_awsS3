import 
    common,
    options

# this file is the tyoe definition for the s3 api taken from the aws docs
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html

type
    UploadPartCommandInput* = object
       
        ## Object data
        Body: Option[openArray[byte] | string]


        ## The bucket name of the uploaded the part.
        Bucket*: string
        
        ## Specify the content length if it can not be determined automatically.
        ContentLength: Option[int]
 
        ## Base64-encoded 128-bit MD5 digest of the part data. Used to verify the integrity of the
        ContentMD5: Option[string]
 
        ## The algorithm used to verify the integrity of the part data.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        ChecksumAlgorithm: Option[ChecksumAlgorithm | string]

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

 
        ## Key of the object to upload. AKA the filepath/filename.
        Key*: string

        ## The ID that identifies the multipart upload.
        UploadId*: string
        
        ## The part number of the part being uploaded. range 1-10000
        PartNumber: int
        
        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerAlgorithm*: Option[string]

        # Server-side encryption (SSE) Key used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerKey*: Option[string]

        # Server-side encryption (SSE) MD5 checksum.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerKeyMD5*: Option[string]

 
        ## Tag to specify if the Requester Pays Buckets
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html"
        RequestPayer*: Option[RequestPayer | string]

        ## List the expected bucket owner for this request. If the bucket is owned by a different owner, the server will return an HTTP 403 (Access Denied) error.
        ## x-amz-expected-bucket-owner
        ExpectedBucketOwner*: Option[string]


    UploadPartOutput* = object
        
        ## The server side encryption algorithm used when storing this object in S3 (e.g., AES256, aws:kms).
        ServerSideEncryption: Option[ServerSideEncryption | string]
 
        ## <p>Entity tag for the uploaded object.</p>
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
 
        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerAlgorithm*: Option[string]

        # Server-side encryption (SSE) MD5 checksum.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerKeyMD5*: Option[string]


        ## AWS Key Management Service (AWS KMS)
        SSEKMSKeyId*: Option[string]
 
        ## S3 Bucket Key for server-side encryption AWS KMS (SSE-KMS)
        BucketKeyEnabled*: Option[bool]
 
        #  Requester Pays status for the specified bucket.
        RequestCharged*: Option[RequestCharged | string]

