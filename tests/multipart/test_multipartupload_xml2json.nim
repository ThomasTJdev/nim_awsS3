# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

import
  xmlparser,
  xmltree,
  json,
  tables,
  strtabs,
  unittest,
  sequtils

import
  jsony

import
  src/api/utils,
  src/api/xml2Json



suite "xml2Json for multipart":
    type
        Xml2JsonTestRoot = object
            id: string
            child1: string
            child2: seq[string]
            child3: Table[string, string]
            child5: string
        Xml2JsonTest = object
            root: Xml2JsonTestRoot

    let xmlString = """<?xml version="1.0" encoding="UTF-8"?>
<root id="123">
    <child1>value1</child1>
    <child2>value2</child2>
    <child2>value3</child2>
    <child3>
        <child4>value4</child4>
    </child3>
    <Child5>value5</Child5>
</root>"""

    let expectedJson = """{"root":{"id":"123","child1":"value1","child2":["value2","value3"],"child3":{"child4":"value4"},"Child5":"value5"}}"""
    let expectedJsonSplitAttr = """{"root":{"attributes":{"id":"123"},"child1":"value1","child2":["value2","value3"],"child3":{"child4":"value4"},"Child5":"value5"}}"""
    test "xml->jsonString":
        let xml = xmlString.parseXml()
        check:
            $xml.xml2Json() == expectedJson
            $xml.xml2Json(true) == expectedJsonSplitAttr

    test "xml->json->obj":

        let xml = xmlString.parseXml()
        let json = xml.xml2Json()
        let jsonString = json.toJson()
        let obj = jsonString.fromJson(Xml2JsonTest)
        let expectedObject = Xml2JsonTest(
            root: Xml2JsonTestRoot(
                id: "123",
                child1: "value1",
                child2: @["value2", "value3"],
                child3: {"child4": "value4"}.toTable(),
                child5: "value5"
            )
        )
        check:

            obj == expectedObject

    test "xml quotes":
        let xmlString = """ <?xml version="1.0" encoding="UTF-8"?><ETag>&quot;48ad599540f59071982d4a00c6c5928d-4&quot;</ETag>"""
        let  expectedJson = """{"ETag":"48ad599540f59071982d4a00c6c5928d-4"}"""
        let xmlString1 = """ <?xml version="1.0" encoding="UTF-8"?><root><ETag>&quot;48ad599540f59071982d4a00c6c5928d-4&quot;</ETag></root>"""
        let  expectedJson1 = """{"root":{"ETag":"48ad599540f59071982d4a00c6c5928d-4"}}"""
        var n0 = newElement("ETag")
        let n1 = newText("\"")
        let n2 = newText("48ad599540f59071982d4a00c6c5928d-4")
        n0.add(n1)
        n0.add(n2)
        n0.add(n1)

        let root = newElement("root")
        root.add(n0)

        check:
            xmlString.parseXml().xml2Json().toJson() == expectedJson
            n0.xml2Json().toJson() == expectedJson
            root.xml2Json().toJson() == expectedJson1
            xmlString1.parseXml().xml2Json().toJson() == expectedJson1

    test "jsony object":
        let json = """{"Xml2JsonTestRoot":{"id":"123","child1":"value1","child2":["value2","value3"],"child3":{"child4":"value4"},"Child5":"value5"}}"""
        let obj = json.parseJson()["Xml2JsonTestRoot"].toJson().fromJson(Xml2JsonTestRoot)

        check:
            obj.id == "123"
            obj.child1 == "value1"
            obj.child2 == @["value2", "value3"]
            obj.child3 == {"child4": "value4"}.toTable()
            obj.child5 == "value5"