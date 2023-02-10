import 
    unittest,
    strformat,
    strutils,
    uri,
    options,
    algorithm,
    times

import 
    ../models/models,
    jsony




proc dumpHook*(s: var string, v: Option[DateTime]) =
    s.add("\"" & v.get().format("yyyy-mm-dd'T'hh:mm:ss'.'fff'Z'") & "\"" )

proc dumpHook*(s: var string, v: DateTime) =
    s.add("\"" & v.format("yyyy-mm-dd'T'hh:mm:ss'.'fff'Z'") & "\"" )

proc parseHook*(s: string, i: var int, v: var DateTime) =
    ## jsony time convert
    ## runs through times and tries to parse them
    var str: string
    parseHook(s, i, str)
    var timeFormats = @["yyyy-MM-dd", "yyyy-MM-dd hh:mm:ss", "yyyy-mm-dd'T'hh:mm:ss'.'fff'Z'"]
    for fmt in timeFormats:
        try:
            v = parse(str, fmt)
            return
        except:
            continue
    raise newException(ValueError, "Invalid date format: " & str)

proc parseHook*(s: string, i: var int, v: var int) =
    ## attempt to parse Ints
    var str: string
    parseHook(s, i, str)
    v = parseInt(str)

proc parseHook*(s: string, i: var int, v: var float) =
    ## attempt to parse Floats
    var str: string
    parseHook(s, i, str)
    v = parseFloat(str)

proc parseHook*(s: string, i: var int, v: var Option[bool]) =
    # attempt to parse Bools
    var str: string
    parseHook(s, i, str)
    v = some(parseBool(str))

    
proc renameHook*(v: object, fieldName: var string) =
    # loosely match field  to names
    # MyField -> myfield
    # myField -> myFields
    runnableExamples:
        type
            MyTest = object
                id: string
                myFancyField: string

        var myJson = """
        {
            "Id": "someId",
            "MyFancyField": "foo"
        }
        """
        let myTest =  myJson.fromJson(MyTest)
        echo myTest

    # MyField -> myField
    var tempFieldName = fieldName
    tempFieldName[0] = tempFieldName[0].toLowerAscii()
    for x , _  in v.fieldPairs():
        if tempFieldName == x:
            fieldName = tempFieldName
            return
    # try to match with an upload-> uploads
    tempFieldName &= "s"
    for x , _  in v.fieldPairs():
        if tempFieldName == x:
            fieldName = tempFieldName
            return


proc toKebab(s: string): string =
    ## myapi  -> myapi
    ## myApi  -> my-api
    ## MyApi  -> my-api
    ## MyAPI  -> my-api
    ## my_api -> my-api
    ## my_Api -> my-api
    ## my_API -> my-api
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

   
    
type
    LetterCase = enum
        None = "None",
        PascalCase = "PascalCase",
        CamelCase = "camelCase",
        SnakeCase = "snake_case",
        KebabCase = "kebab-case"


proc amzUrlEncodeObject[T](obj: T, letterCase: LetterCase = PascalCase): string =   
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
        var amzKey = case letterCase:
            # of PascalCase: key.toPascal()
            # of CamelCase: key.toCamel()
            # of SnakeCase: key.toSnake()
            of KebabCase: key.toKebab()
            else: key

        when val is Option:
            if val.isSome():
                keyVals.add((amzKey, $(val.get())))
        else:
            keyVals.add((amzKey, $val))
    
    keyVals.sort()

    return encodeQuery(keyVals)


suite "utility functions":
    test "toKebab":
        check:
            "myapi".toKebab() == "myapi"
            "myApi".toKebab() == "my-api"
            "MyApi".toKebab() == "my-api"
            "MyAPI".toKebab() == "my-api"
            "my_api".toKebab() == "my-api"
            "my_Api".toKebab() == "my-api"
            "my_API".toKebab() == "my-api"


    test "encodeUrl-kebab":
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
        let expectedKebab = "bucket=mybucket&delimiter=%2F&encoding-type=url&expected-bucket-owner=mybucketowner&key-marker=mykey&max-uploads=1000&prefix=myprefix&upload-id-marker=myuploadid"
        check listMultipartUploadsRequest.amzUrlEncodeObject(KebabCase) == expectedKebab

    test "jsony loose frist char":
        type
            MyObject = object
                id: string
                myFancyField: string

        var myJson = """
        {
            "Id": "someId",
            "MyFancyField": "foo"
        }
        """
        let myObject =  myJson.fromJson(MyObject)
        let expectedObject = MyObject(id: "someId", myFancyField: "foo")
        check:
            myObject == expectedObject

    test "parse time":

        let expectedTime = parse("2023-02-09T08:24:35.000Z", initTimeFormat "yyyy-MM-dd\'T\'HH:mm:ss\'.\'fff\'Z\'")