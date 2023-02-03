import 
    options


type
  ListMultipartUploadsRequest* = object

    Bucket: string
 
    Delimiter: Option[string]
 
    EncodingType: Option[string]
 
    KeyMarker: Option[string]
 
    MaxUploads: Option[int]
 
    Prefix: Option[string]
 
    UploadIdMarker: Option[string]
 
    ExpectedBucketOwner: Option[string]


