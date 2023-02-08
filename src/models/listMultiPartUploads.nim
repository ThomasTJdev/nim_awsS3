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
    bucket*: string
        
    ## The character you want to use to group the keys.
    ## delimiter
    delimiter*: Option[string]
 
    ## Request AWS S3 to encode the object keys in the response and specifies the encoding
    ## encoding-type
    encodingType*: Option[string]

    ## Specifies the upload part with the upload-id-marker
    ## key-marker
    keyMarker*: Option[string]
 
    ## sets the maximum number of uploads to return. range 1-1000
    ## max-uploads
    maxUploads*: Option[int]
 
    ## List in-progress uploads only for those keys that begin with the specified prefix.
    ## prefix
    prefix*: Option[string]
  
    ## Together with the key-marker, specifies the upload after which listing should begin with.
    ## upload-id-marker
    uploadIdMarker*: Option[string]

    ## List the expected bucket owner for this request. If the bucket is owned by a different owner, the server will return an HTTP 403 (Access Denied) error.
    ## x-amz-expected-bucket-owner
    expectedBucketOwner*: Option[string]


  ListMultipartUploadsResult* = object
    ## The bucket name of the uploaded the part.
    ## bucket
    bucket*: string

    ## If you specify a delimiter in your request, then the response includes a CommonPrefixes.
    eommonPrefixes*: Option[seq[CommonPrefix]]

    ## The character specified to use to group the keys.
    ## delimiter
    delimiter*: Option[string]

    ## Request AWS S3 to encode the object keys in the response and specifies the encoding
    ## encoding-type
    encodingType*: Option[string]


    ## Indicates whether the returned list of multipart uploads is truncated.
    isTruncated*: Option[bool]

    ## Specifies the upload part with the upload-id-marker
    ## key-marker
    keyMarker*: Option[string]

    ## Together with the key-marker, specifies the upload after which listing should begin with.
    ## upload-id-marker
    uploadIdMarker*: Option[string]

    ## Maximum number of multipart uploads that could have been included in the response.
    maxUploads*: Option[int]

    ## When a list is truncated, this element specifies the value that should be used for the key-marker request parameter in a subsequent request.
    nextKeyMarker*: Option[string]

    ## List in-progress uploads only for those keys that begin with the specified prefix.
    ## prefix
    prefix*: Option[string]

    ## If the list is truncated, this element specifies the value that should be used for the upload-id-marker request parameter in a subsequent request.
    nextUploadIdMarker*: Option[string]

    ## the container for the list of multipart uploads.
    uploads*: Option[seq[MultipartUpload]]