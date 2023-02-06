
import 
    common,
    options,
    times,
    tables

# this file is the tyoe definition for the s3 api taken from the aws docs
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html

type
    CreateMultipartUploadOutput* = object
        
        ## specified abort date for incomplete multipart uploads
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
        AbortDate*: Option[DateTime]

        ## specified abort rule id for incomplete multipart uploads. "x-amz-abort-date"
        AbortRuleId*: Option[string]

        ## The bucket name upload the part to.
        Bucket: string

        ## Key of the object to upload. AKA the filepath/filename.
        Key: string

        ## The ID that identifies the multipart upload
        UploadId: string

        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        ServerSideEncryption: Option[string]

        # Server-side encryption (SSE) Key used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerKey: Option[string]

        # Server-side encryption (SSE) MD5 checksum.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        SSECustomerKeyMD5: Option[string]

        ## AWS Key Management Service (AWS KMS)
        SSEKMSKeyId*: Option[string]

        ## AWS KMS Encryption Context
        SSEKMSEncryptionContext*: Option[string]

        ## S3 Bucket Key for server-side encryption AWS KMS (SSE-KMS)
        BucketKeyEnabled*: Option[bool]

        #  Requester Pays status for the specified bucket.
        RequestCharged*: Option[RequestCharged | string]

        ## The algorithm used check the integrity of the object during the transfer.
        ChecksumAlgorithm*: Option[ChecksumAlgorithm | string]


type 
    CreateMultipartUploadCommandInput* = object
        ## ACL to apply to the object.
        ACL*: Option[ObjectCannedACL | string]

        ## The bucket name upload the part to.
        Bucket*: string

        CacheControl*: Option[string]

        ContentDisposition*: Option[string]

        ContentEncoding*: Option[string]

        ContentLanguage*: Option[string]

        ## MIME type
        ContentType*: Option[string]

        # The date that the multipart upload is to expire.
        Expires*: Option[DateTime]

        ## Grant READ, READ_ACP, and WRITE_ACP permissions on the upload.
        GrantFullControl*: Option[string]

        ## Grant READ permissions on the upload.
        GrantRead*: Option[string]

        ## Grant READACP permissions on the upload.
        GrantReadACP*: Option[string]

        ## Grant WRITEACP permissions on the upload.
        GrantWriteACP*: Option[string]

        ## Key of the file to upload. AKA the filepath/filename.
        Key*: string

        ## A map of metadata to store with the file in S3
        Metadata*: Option[Table[string, string]]

        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        ServerSideEncryption*: Option[ServerSideEncryption | string]

        ## Storage class to be used
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html   
        StorageClass*: Option[StorageClass | string]

        ## Specifies the redirect url if the bucket is being used as a website.
        WebsiteRedirectLocation*: Option[string]

        ## The algorithm used to encrypt the upload.
        SSECustomerAlgorithm*: Option[string]

        ## specifies the customer encryption key. Must match "x-amz-server-side-encryption-customer-algorithm" in headers
        SSECustomerKey*: Option[string]

        ## The MD5 Hash of the customer key to be used for encryption. To verify the integrity of the customer key.
        SSECustomerKeyMD5*: Option[string]

        ## Specify the SSEKM Key id to be used from AWS:KMS to encrypt the upload.
        SSEKMSKeyId*: Option[string]

        ## Specify the SSEKM Encryption Context to be used from AWS:KMS to encrypt the upload.
        SSEKMSEncryptionContext*: Option[string]

        ## Specify to use S3 Bucket Key for server-side encryption AWS KMS (SSE-KMS)
        BucketKeyEnabled*: Option[bool]

        ## Requester Payer for the specified upload.
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
        RequestPayer*: Option[RequestPayer | string]

        ## Tag set of the upload. must be URL encoded.
        Tagging*: Option[string]

        ## Specifies the object lock mode that you want to apply to the uploaded object.
        ObjectLockMode*: Option[ObjectLockMode | string]

        ## Specifies the date and time when you want the object lock to expire.
        ObjectLockRetainUntilDate*: Option[DateTime]

        ## Specifies whether you want to apply a Legal Hold to the uploaded object.
        ObjectLockLegalHoldStatus*: Option[ObjectLockLeagalHoldStatus | string]

        ## ID of the expected bucket owner. If the bucket is owned by a different account the request will fail with error code 403.
        ExpectedBucketOwner*: Option[string]

        ## The algorithm used check the integrity of the object during the transfer.
        ChecksumAlgorithm*: Option[ChecksumAlgorithm | string]