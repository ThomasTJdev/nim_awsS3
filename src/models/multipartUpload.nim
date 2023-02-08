import 
    common,
    options,
    times

type
    MultipartUpload* = object
        ## ID of the multipart upload
        uploadId*: Option[string]

        ## Key of the object to upload. AKA the filepath/filename.
        key*: string

        ## Date and time at which the multipart upload was initiated
        initiated*: Option[DateTime]

        ## The class of storage used to store the object
        storageClass*: Option[StorageClass]

        ## Specifies the owner of the object that is part of the multipart upload.
        owner*: Option[Owner]

        ## Identifies who initiated the multipart upload
        initiator*: Option[Initiator]

        ## The algorithm that was used to create a checksum of the object
        checksumAlgorithm*: Option[ChecksumAlgorithm]