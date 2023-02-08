import 
    unittest,
    strformat,
    strutils,
    uri,
    options,
    algorithm

import ../models/models


proc toKebab(s: string): string =
    # myapi  -> myapi
    # myApi  -> my-api
    # MyApi  -> my-api
    # MyAPI  -> my-api
    # my_var -> my-var
    # my_Api -> my-api
    # my_API -> my-api
    result = s
    var insertDash = true
    var i = 0
    while i <= result.high:
        if i == 0:
            result[i] = result[i].toLowerAscii()

        if result[i] == '_':
            result[i] = '-'
            insertDash = false
            i.inc()
        if result[i] notin {'A'..'Z'}:
            insertDash = true
        if result[i] in {'A'..'Z'}:
            result[i] = result[i].toLowerAscii()
            if insertDash:
                result.insert("-", i)
                insertDash = false
                i.inc()
        i.inc()
        




proc amzUrlEncodeObject[T](obj: T): string =   
    #  Encodes an object into a url encoded string.
    #  ListMultipartUploadsRequest
    #    bucket: "mybucket"
    #    delimiter: "/"
    #    encoding-type: "url"
    #    key-marker: "mykey"
    #    max-uploads: 1000
    #    prefix: "myprefix"
    #    upload-id-marker: "myuploadid"
    #  becomes
    #    bucket=mybucket&delimiter=%2F&encoding-type=url&key-marker=mykey&max-uploads=1000&prefix=myprefix&upload-id-marker=myuploadid

    var keyVals: seq[(string, string)] = @[]

    # convert to snake case my_Var to my_var
    # convert pascal myVar to my-var
    # 
    for key, val in obj.fieldPairs():
        when val is Option:
            if val.isSome():
                keyVals.add((key.toKebab(), $(val.get())))
        else:
            keyVals.add((key.toKebab(), $val))
    
    keyVals.sort()

    return encodeQuery(keyVals)




suite "utility functions":
    test "toKebab":
        check:
            "myapi".toKebab() == "myapi"
            "myApi".toKebab() == "my-api"
            "MyApi".toKebab() == "my-api"
            "MyAPI".toKebab() == "my-api"
            "my_var".toKebab() == "my-var"
            "my_Api".toKebab() == "my-api"
            "my_API".toKebab() == "my-api"
            
    test "encodeUrl":
        let listMultipartUploadsRequest = ListMultipartUploadsRequest(
            bucket: "mybucket",
            delimiter: some("/"),
            encodingType: some("url"),
            keyMarker: some("mykey"),
            maxUploads: some(1000),
            prefix: some("myprefix"),
            uploadIdMarker: some("myuploadid"),
            expectedBucketOwner: some("mybucketowner"),
        )
        let expected = "bucket=mybucket&delimiter=%2F&encoding-type=url&expected-bucket-owner=mybucketowner&key-marker=mykey&max-uploads=1000&prefix=myprefix&upload-id-marker=myuploadid"
        check listMultipartUploadsRequest.amzUrlEncodeObject() == expected

