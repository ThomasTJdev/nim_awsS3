import
    options,
    httpcore,
    options


type
    ## this file is the type definition for the s3 api was created from the aws docs
    ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    ResponseMetadata* = object
        ## The status code of the last HTTP response received for this operation.
        httpStatusCode*: Option[HttpCode]

        ## A unique identifier for the last request sent for this operation
        ## #debugging
        requestId*: Option[string]

        ## An identifier for the last request sent.
        ## #debugging
        extendedRequestId*: Option[string]

        ## An identifier of the last request sent.
        ## #debugging
        cfId*: Option[string]

        ## The number of times this operation was attempted.
        attempts*: Option[int]

        ## Total time spent waiting between retries in milliseconds.
        totalRetryDelay*: Option[int]

    MetadataBearer* = object
        ## Metadata pertaining to this request.
        `$metadata`*: ResponseMetadata
