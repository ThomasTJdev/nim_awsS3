import 
    common,
    options

type
    AbortMultipartUploadRequest* = object

        Bucket: string

        Key: string

        UploadId: string

        RequestPayer: Option[RequestPayer | string]
        
        ExpectedBucketOwner: Option[string]