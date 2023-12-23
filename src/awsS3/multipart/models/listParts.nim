import
    options,
    common,
    times,
    part


type
    ## this file is the type definition for the s3 api was created from the aws docs
    ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html

    ListPartsRequest* = object
        ## The bucket name of the uploaded the part.
        ## bucket
        bucket*: string

        key*: Option[string]

        maxParts*: Option[string]

        partNumberMarker*: Option[string]

        uploadId*: Option[string]

        ## List the expected bucket owner for this request. If the bucket is owned by a different owner, the server will return an HTTP 403 (Access Denied) error.
        ## x-amz-expected-bucket-owner
        expectedBucketOwner*: Option[string]

        requestPayer*: Option[string]

        sseCustomerAlgorithm*: Option[string]

        sseCustomerKey*: Option[string]

        sseCustomerKeyMD5*: Option[string]


    ListPartsResult* = object

        abortDate*: Option[DateTime]

        abortRuleId*: Option[string]

        requestCharged*: Option[string]

        listPartsResult: string

        bucket*: Option[string]

        checkSumAlgorithm: Option[CheckSumAlgorithm]

        initiator*: Initiator

        isTruncated*: Option[bool]

        key*: Option[string]

        maxParts*: Option[int]

        nextPartNumberMarker*: Option[int]

        owner*: Owner

        parts: Option[seq[Part]]

        partNumberMarker*: Option[int]

        storageClass*: Option[StorageClass]

        uploadId*: Option[string]


