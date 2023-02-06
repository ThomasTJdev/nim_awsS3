import 
    options,
    common,
    multipartUpload

# this file is the tyoe definition for the s3 api taken from the aws docs
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html

type
  ListMultipartUploadsRequest* = object

    ## The bucket name of the uploaded the part.
    ## bucket
    Bucket*: string
        
    ## The character you want to use to group the keys.
    ## delimiter
    Delimiter*: Option[string]
 
    ## Request AWS S3 to encode the object keys in the response and specifies the encoding
    ## encoding-type
    EncodingType*: Option[string]
 
    ## Specifies the upload part with the upload-id-marker
    ## key-marker
    KeyMarker*: Option[string]
 
    ## sets the maximum number of uploads to return. range 1-1000
    ## max-uploads
    MaxUploads*: Option[int]
 
    ## List in-progress uploads only for those keys that begin with the specified prefix.
    ## prefix
    Prefix*: Option[string]
  
    ## Together with the key-marker, specifies the upload after which listing should begin with.
    ## upload-id-marker
    UploadIdMarker*: Option[string]

    ## List the expected bucket owner for this request. If the bucket is owned by a different owner, the server will return an HTTP 403 (Access Denied) error.
    ## x-amz-expected-bucket-owner
    ExpectedBucketOwner*: Option[string]


  ListMultipartUploadsOutput* = object
    ## The bucket name of the uploaded the part.
    ## bucket
    Bucket*: string

    ## If you specify a delimiter in your request, then the response includes a CommonPrefixes.
    CommonPrefixes*: Option[seq[CommonPrefix]]

    ## The character specified to use to group the keys.
    ## delimiter
    Delimiter*: Option[string]

    ## Request AWS S3 to encode the object keys in the response and specifies the encoding
    ## encoding-type
    EncodingType*: Option[string]


    ## Indicates whether the returned list of multipart uploads is truncated.
    IsTruncated*: Option[bool]

    ## Specifies the upload part with the upload-id-marker
    ## key-marker
    KeyMarker*: Option[string]

    ## Together with the key-marker, specifies the upload after which listing should begin with.
    ## upload-id-marker
    UploadIdMarker*: Option[string]

    ## Maximum number of multipart uploads that could have been included in the response.
    MaxUploads*: Option[int]

    ## When a list is truncated, this element specifies the value that should be used for the key-marker request parameter in a subsequent request.
    NextKeyMarker*: Option[string]

    ## List in-progress uploads only for those keys that begin with the specified prefix.
    ## prefix
    Prefix*: Option[string]

    ## If the list is truncated, this element specifies the value that should be used for the upload-id-marker request parameter in a subsequent request.
    NextUploadIdMarker*: Option[string]

    ## the container for the list of multipart uploads.
    Uploads*: Option[seq[MultipartUpload]]