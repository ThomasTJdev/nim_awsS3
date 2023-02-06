import 
  options

# enums
type
  ObjectCannedACL* = enum
    authenticated_read = "authenticated-read",
    aws_exec_read = "aws-exec-read",
    bucket_owner_full_control = "bucket-owner-full-control",
    bucket_owner_read = "bucket-owner-read",
    private = "private",
    public_read = "public-read",
    public_read_write = "public-read-write"

  CheckSumAlgorithm* = enum
    CRC32 = "CRC32",
    CRC32C = "CRC32C",
    SHA1 = "SHA1",
    SHA256 = "SHA256"

  CopyReplace* = enum
    COPY = "COPY",
    REPLACE = "REPLACE"

  OnOff = enum
    OFF = "OFF",
    ON = "ON"

  ObjectLockLeagalHoldStatus* = OnOff
  
  ObjectLockMode* = enum
    COMPLIANCE = "COMPLIANCE",
    GOVERNANCE = "GOVERNANCE"

  ServerSideEncryption* = enum
    AES256 = "AES256",
    awsKms = "aws:kms"

  StorageClass* = enum
    DEEP_ARCHIVE = "DEEP_ARCHIVE",
    GLACIER = "GLACIER",
    GLACIER_IR = "GLACIER_IR",
    INTELLIGENT_TIERING = "INTELLIGENT_TIERING",
    ONEZONE_IA = "ONEZONE_IA",
    OUTPOSTS = "OUTPOSTS",
    REDUCED_REDUNDANCY = "REDUCED_REDUNDANCY",
    STANDARD = "STANDARD",
    STANDARD_IA = "STANDARD_IA"

  TaggingDirective* = CopyReplace
  MetadataDirective* = CopyReplace

  Request = enum
    requester = "requester"

  RequestPayer* = Request
  RequestCharged* = Request
  
  EncodingType* = enum
    url = "url"
  
  CommonPrefix* = object
    Prefix: Option[string]

  DisplayAccount = object
    DisplayName: Option[string]
    ID: Option[string]

  Owner* = DisplayAccount
  Initiator* = DisplayAccount

# models