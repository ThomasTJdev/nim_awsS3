
import 
    common,
    options,
    times,
    tables

# this file is the tyoe definition for the s3 api taken from the aws docs
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html


type 
    CreateMultipartUploadCommandInput* = object
        ## ACL to apply to the object.
        # acl*: Option[ObjectCannedACL | string]
        acl*: Option[ObjectCannedACL]

        ## The bucket name upload the part to.
        bucket*: string

        cacheControl*: Option[string]

        contentDisposition*: Option[string]

        contentEncoding*: Option[string]

        contentLanguage*: Option[string]

        ## MIME type
        contentType*: Option[string]

        # The date that the multipart upload is to expire.
        expires*: Option[DateTime]

        ## Grant READ, READ_ACP, and WRITE_ACP permissions on the upload.
        grantFullControl*: Option[string]

        ## Grant READ permissions on the upload.
        grantRead*: Option[string]

        ## Grant READACP permissions on the upload.
        grantReadACP*: Option[string]

        ## Grant WRITEACP permissions on the upload.
        grantWriteACP*: Option[string]

        ## Key of the file to upload. AKA the filepath/filename.
        key*: string

        ## A map of metadata to store with the file in S3
        # metadata*: Option[Table[string, string]]

        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        serverSideEncryption*: Option[ServerSideEncryption]

        ## Storage class to be used
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html   
        # storageClass*: Option[StorageClass | string]
        storageClass*: Option[StorageClass]

        ## Specifies the redirect url if the bucket is being used as a website.
        websiteRedirectLocation*: Option[string]

        ## The algorithm used to encrypt the upload.
        sseCustomerAlgorithm*: Option[string]

        ## specifies the customer encryption key. Must match "x-amz-server-side-encryption-customer-algorithm" in headers
        sseCustomerKey*: Option[string]

        ## The MD5 Hash of the customer key to be used for encryption. To verify the integrity of the customer key.
        sseCustomerKeyMD5*: Option[string]

        ## Specify the SSEKM Key id to be used from AWS:KMS to encrypt the upload.
        sseKMSKeyId*: Option[string]

        ## Specify the SSEKM Encryption Context to be used from AWS:KMS to encrypt the upload.
        sseKMSEncryptionContext*: Option[string]

        ## Specify to use S3 Bucket Key for server-side encryption AWS KMS (SSE-KMS)
        bucketKeyEnabled*: Option[bool]

        ## Requester Payer for the specified upload.
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
        requestPayer*: Option[string]

        ## Tag set of the upload. must be URL encoded.
        tagging*: Option[string]

        ## Specifies the object lock mode that you want to apply to the uploaded object.
        objectLockMode*: Option[ObjectLockMode]

        ## Specifies the date and time when you want the object lock to expire.
        objectLockRetainUntilDate*: Option[DateTime]

        ## Specifies whether you want to apply a Legal Hold to the uploaded object.
        objectLockLegalHoldStatus*: Option[ObjectLockLeagalHoldStatus]

        ## ID of the expected bucket owner. If the bucket is owned by a different account the request will fail with error code 403.
        expectedBucketOwner*: Option[string]

        ## The algorithm used check the integrity of the object during the transfer.
        checksumAlgorithm*: Option[ChecksumAlgorithm]

    CreateMultipartUploadResult* = object
        
        ## specified abort date for incomplete multipart uploads
        ## https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
        abortDate*: Option[DateTime]

        ## specified abort rule id for incomplete multipart uploads. "x-amz-abort-date"
        abortRuleId*: Option[string]

        ## The bucket name upload the part to.
        bucket*: string

        ## Key of the object to upload. AKA the filepath/filename.
        key*: string

        ## The ID that identifies the multipart upload
        uploadId*: string

        # Server-side encryption (SSE) algorithm used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        serverSideEncryption*: Option[string]

        # Server-side encryption (SSE) Key used to encrypt the upload.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        sseCustomerKey*: Option[string]

        # Server-side encryption (SSE) MD5 checksum.
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
        sseCustomerKeyMD5*: Option[string]

        ## AWS Key Management Service (AWS KMS)
        sseKMSKeyId*: Option[string]

        ## AWS KMS Encryption Context
        sseKMSEncryptionContext*: Option[string]

        ## S3 Bucket Key for server-side encryption AWS KMS (SSE-KMS)
        bucketKeyEnabled*: Option[bool]

        #  Requester Pays status for the specified bucket.
        requestCharged*: Option[string]

        ## The algorithm used check the integrity of the object during the transfer.
        checksumAlgorithm*: Option[ChecksumAlgorithm]