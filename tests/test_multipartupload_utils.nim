# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

import
    unittest,
    strutils,
    options,
    times

import
    jsony

import
  src/api/utils


suite "utility functions for multipart upload":
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


