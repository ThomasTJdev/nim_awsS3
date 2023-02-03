import
  options,
  httpcore,
  options

type
  ResponseMetadata* = object
  
    ## The status code of the last HTTP response received for this operation.
    httpStatusCode*: Option[HttpCode]

    ## A unique identifier for the last request sent for this operation. Often
    ## requested by AWS service teams to aid in debugging.
    requestId*: Option[string]

    ## A secondary identifier for the last request sent. Used for debugging.
    extendedRequestId*: Option[string]

    ## A tertiary identifier for the last request sent. Used for debugging.
    cfId*: Option[string]

    ## The number of times this operation was attempted.
    attempts*: Option[int]

    ## The total amount of time (in milliseconds) that was spent waiting between
    ## retry attempts.
    totalRetryDelay*: Option[int]

  MetadataBearer* = object
  
    ## Metadata pertaining to this request.
    `$metadata`*: ResponseMetadata
