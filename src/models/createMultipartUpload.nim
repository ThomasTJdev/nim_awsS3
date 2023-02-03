
import 
    common,
    options,
    times,
    tables


type
    CreateMultipartUploadOutput* = object

        AbortDate*: Option[DateTime]

        AbortRuleId*: Option[string]

        Bucket*: Option[string]

        Key*: Option[string]

        UploadId*: Option[string]

        ServerSideEncryption*: Option[ServerSideEncryption | string]

        SSECustomerAlgorithm*: Option[string]

        SSECustomerKeyMD5*: Option[string]

        SSEKMSKeyId*: Option[string]

        SSEKMSEncryptionContext*: Option[string]

        BucketKeyEnabled*: Option[bool]

        RequestCharged*: Option[RequestCharged | string]

        ChecksumAlgorithm*: Option[ChecksumAlgorithm | string]


type 
  CreateMultipartUploadCommandInput* = object

      ACL*: Option[ObjectCannedACL | string]

      Bucket*: string

      CacheControl*: Option[string]

      ContentDisposition*: Option[string]

      ContentEncoding*: Option[string]

      ContentLanguage*: Option[string]

      ContentType*: Option[string]

      Expires*: Option[DateTime]

      GrantFullControl*: Option[string]

      GrantRead*: Option[string]

      GrantReadACP*: Option[string]

      GrantWriteACP*: Option[string]

      Key*: string

      Metadata*: Option[Table[string, string]]

      ServerSideEncryption*: Option[ServerSideEncryption | string]

      StorageClass*: Option[StorageClass | string]

      WebsiteRedirectLocation*: Option[string]

      SSECustomerAlgorithm*: Option[string]

      SSECustomerKey*: Option[string]

      SSECustomerKeyMD5*: Option[string]

      SSEKMSKeyId*: Option[string]

      SSEKMSEncryptionContext*: Option[string]

      BucketKeyEnabled*: Option[bool]

      RequestPayer*: Option[RequestPayer | string]

      Tagging*: Option[string]

      ObjectLockMode*: Option[ObjectLockMode | string]

      ObjectLockRetainUntilDate*: Option[DateTime]

      ObjectLockLegalHoldStatus*: Option[ObjectLockLeagalHoldStatus | string]

      ExpectedBucketOwner*: Option[string]

      ChecksumAlgorithm*: Option[ChecksumAlgorithm | string]