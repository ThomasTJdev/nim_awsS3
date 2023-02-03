import
    common,
    options

type
    CompletedPart* = object

        ETag: Option[string]

        ChecksumCRC32: Option[string]

        ChecksumCRC32C: Option[string]

        ChecksumSHA1: Option[string]

        ChecksumSHA256: Option[string]

        PartNumber: Option[int]


    CompletedMultipartUpload* = object
    
        Parts: Option[seq[CompletedPart]]

    CompleteMultipartUploadRequest* = object

        Bucket: string
        
        Key: string

        MultipartUpload: Option[CompletedMultipartUpload]

        UploadId: string

        ChecksumCRC32: Option[string]

        ChecksumCRC32C: Option[string]

        ChecksumSHA1: Option[string]

        ChecksumSHA256: Option[string]

        RequestPayer: Option[RequestPayer | string]

        ExpectedBucketOwner: Option[string]

        SSECustomerAlgorithm: Option[string]

        SSECustomerKey: Option[string]

        SSECustomerKeyMD5: Option[string]
