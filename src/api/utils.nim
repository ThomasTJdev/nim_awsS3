import
    unittest,
    strutils,
    options,
    times

import
    jsony

proc parseHook*[T](s: string, i: var int, v: var Option[seq[T]]) =
    eatSpace(s, i)
    if i + 3 < s.len and
            s[i+0] == 'n' and
            s[i+1] == 'u' and
            s[i+2] == 'l' and
            s[i+3] == 'l':
        i += 4
        return
    if s[i] == '[':
        var v2: seq[T]
        parseHook(s, i, v2)
        v = some(v2)
    else:
        var v2: T
        parseHook(s, i, v2)
        v = some(@[v2])


proc dumpHook*(s: var string, v: Option[DateTime]) =
  if v.isNone:
    s.add("null")
  else:
    s.add("\"" & v.get().format("yyyy-MM-dd'T'hh:mm:ss'.'fffzzz") & "\"" )

proc dumpHook*(s: var string, v: DateTime) =
    s.add("\"" & v.format("yyyy-MM-dd'T'hh:mm:ss'.'fffzzz") & "\"" )

proc parseHook*(s: string, i: var int, v: var DateTime) =
    ## jsony time convert
    ## runs through times and tries to parse them
    var str: string
    parseHook(s, i, str)
    var timeFormats = @[
        "yyyy-MM-dd", 
        "yyyy-MM-dd hh:mm:ss", 
        "yyyy-MM-dd hh:mm:ssz", 
        "yyyy-MM-dd hh:mm:sszz",
        "yyyy-MM-dd hh:mm:sszzzz", 
        "yyyy-MM-dd'T'hh:mm:ss'.'fff",
        "yyyy-MM-dd'T'hh:mm:ss'.'fffz", 
        "yyyy-MM-dd'T'hh:mm:ss'.'fffzz", 
        "yyyy-MM-dd'T'hh:mm:ss'.'fffzzz",
        "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'", 
        "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'zz",
        "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'zzz",
        ]
    for fmt in timeFormats:
        try:
            v = parse(str, fmt, utc())
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

suite "utility functions":
    test "check amazon time format time":
        let time = parse("2023-02-09T08:24:35.000Z", "yyyy-MM-dd\'T\'HH:mm:ss\'.\'fffzzz", utc())
        let expectedTime = fromUnix(1675931075).utc() # 2023-02-09T08:24:35.000Z
        check:
            time == expectedTime
    test "jsony time convert - parse":
        type
            MyTimeObject = object
                time: DateTime
        let json = """[
            {"time":"2023-02-09T08:24:35.000Z"},
            {"time":"2023-02-09T08:24:35.000Z+00:00"},
            {"time":"2023-02-09T08:24:35.000Z+01:00"},
        ]"""
        let timesArr = json.fromJson(seq[MyTimeObject])
        check:
            timesArr[0].time == dateTime(2023, mFeb, 9, 8, 24, 35, 0, utc()) # 2023-02-09T08:24:35.000Z
            timesArr[1].time == dateTime(2023, mFeb, 9, 8, 24, 35, 0, utc()) # 2023-02-09T08:24:35.000Z
            timesArr[2].time == dateTime(2023, mFeb, 9, 7, 24, 35, 0, utc()) # 2023-02-09T07:24:35.000Z

    test "jsony time convert - dump":
        type
            MyTimeObject = object
                time: DateTime
        let time = dateTime(2023, mFeb, 9, 8, 24, 35, 0, utc()) # 2023-02-09T08:24:35.000Z
        let myTimeObject = MyTimeObject(time: time)
        let json = myTimeObject.toJson()
        check:
            json == """{"time":"2023-02-09T08:24:35.000Z"}"""
            
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

    test "jsony loose object/arr":
        type
            Cat = object
                name: string
            MyType = object
                cat: Option[seq[Cat]]

        let
            d1 = """{"cat":[{"name":"sparky"}]}"""
            d2 = """{"cat":{"name":"sparky"}}"""
            d3 = """{"cat":null}"""

        check:
            d1.fromJson(MyType) == MyType(cat: some(@[Cat(name: "sparky")]))
            d2.fromJson(MyType) == MyType(cat: some(@[Cat(name: "sparky")]))
            d3.fromJson(MyType) == MyType()


            