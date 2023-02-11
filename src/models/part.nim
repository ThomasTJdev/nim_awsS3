import 
    options,
    times,
    common


type
    ## this file is the type definition for the s3 api was created from the aws docs
    ## https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    Part* = object

        ## A base64-encoded, 32-bit CRC32 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumCRC32*: Option[string]

        ## A base64-encoded, 32-bit CRC32C checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumCRC32C*: Option[string]

        ## A base64-encoded, 32-bit SHA1 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumSHA1*: Option[string]

        ## A base64-encoded, 32-bit SHA256 checksum of the uploaded part.
        ## https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
        checksumSHA256*: Option[string]

        eTag*: Option[string]

        lastModified*: Option[DateTime]

        partNumber*: Option[int]

        size*: Option[int]