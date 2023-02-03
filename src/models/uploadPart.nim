import 
    common,
    options

type
    UploadPartCommandInput* = object
       
        Body: Option[openArray[byte] | string]


        Bucket: string
        
        ContentLength: Option[int]
 
        ContentMD5: Option[string]
 
        ChecksumAlgorithm: Option[ChecksumAlgorithm | string]
 
        ChecksumCRC32: Option[string]
 
        ChecksumCRC32C: Option[string]
 
        ChecksumSHA1: Option[string]
 
        ChecksumSHA256: Option[string]
 
        Key: string
        
        PartNumber: int
        
        UploadId: string
        
        SSECustomerAlgorithm: Option[string]
 
        SSECustomerKey: Option[string]
 
        SSECustomerKeyMD5: Option[string]
 
        RequestPayer: Option[RequestPayer | string]
 
        ExpectedBucketOwner: Option[string]


    UploadPartOutput* = object
        
        ServerSideEncryption: Option[ServerSideEncryption | string]
 
        ETag: Option[string]
 
        ChecksumCRC32: Option[string]
 
        ChecksumCRC32C: Option[string]
 
        ChecksumSHA1: Option[string]
 
        ChecksumSHA256: Option[string]
 
        SSECustomerAlgorithm: Option[string]
 
        SSECustomerKeyMD5: Option[string]
 
        SSEKMSKeyId: Option[string]
 
        BucketKeyEnabled: Option[bool]
 
        RequestCharged: Option[RequestCharged | string]
