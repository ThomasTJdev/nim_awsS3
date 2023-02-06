import 
    common,
    options,
    times

type
    MultipartUpload* = object
        ## ID of the multipart upload
        UploadId*: Option[string]

        ## Key of the object to upload. AKA the filepath/filename.
        Key*: string

        ## Date and time at which the multipart upload was initiated
        Initiated*: Option[DateTime]

        ## The class of storage used to store the object
        StorageClass*: Option[StorageClass | string]

        ## Specifies the owner of the object that is part of the multipart upload.
        Owner*: Option[Owner]

        ## Identifies who initiated the multipart upload
        Initiator*: Option[Initiator]

        ## The algorithm that was used to create a checksum of the object
        ChecksumAlgorithm*: Option[ChecksumAlgorithm | string]