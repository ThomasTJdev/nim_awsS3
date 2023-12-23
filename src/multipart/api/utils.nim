import
  std/strutils,
  std/options,
  std/times

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
