import 
    xmlparser,
    xmltree,
    json,
    tables,
    strtabs,
    unittest,
    sequtils

import 
    utils,
    jsony

const escapedChars = @[
    ('<', "&lt;"),
    ('>', "&gt;"),
    ('&', "&amp;"),
    ('"', "&quot;"),
    ('\'', "&apos;")
]
const escapedCharStrings = escapedChars.mapIt($it[0])

proc hasEscapedChar(xmlNode: XmlNode): bool =
    let children = xmlNode.items().toSeq()
    for child in children:
        if child.kind() == xnText:
            if child.text() in escapedCharStrings:
                return true

proc getUnescaptedChar(str: string): string =
    for (c, cs) in escapedChars:
        if str == cs:
            return cs

proc getUnescapedString(xmlNode: XmlNode): string =
    let children = xmlNode.items().toSeq()
    for child in children:
        if child.kind() == xnText:
            if child.text() in escapedCharStrings:
                result.add child.text().getUnescaptedChar()
            else:
                result.add child.text()

proc xml2Json*(xmlNode: XmlNode, splitAttr: bool=false, isFrist: bool=true): JsonNode =
    ## Convert an XML node to a JSON node.
    ## if <Element><Element> the resulting json will be JSNull
    ## if <Element>1000</Element> the resulting json will be JSString not JSInt
    
    # deal with root node.
    if isFrist:
        result = newJObject()
        result[xmlNode.tag()] = xmlNode.xml2Json(splitAttr, false)
        return result
    case xmlNode.kind():
    of xnVerbatimText, xnText:
        result = newJString(xmlNode.text)
    of xnElement:
        # if element has no children return
        let children = xmlNode.items().toSeq()
        if children.len == 0:
            return newJNull()
        # for some reason XML treates escaped charaters as thier own nodes.
        # this fixes that
        if xmlNode.hasEscapedChar():
            result = newJObject()
            return newJString(xmlNode.getUnescapedString())

        result = newJObject()
        # if element has attributes
        if xmlNode.attrsLen() > 0:
            for key, val in xmlNode.attrs().pairs():
                if splitAttr:
                    result["attributes"] = newJObject()
                    result["attributes"][key] = newJString(val)
                else:
                    result[key] = newJString(val)

        # if it has children
        # children need to be added as either an array or object
        # if node has multiple children with the same tag
        # it is assumed to be an array otherwise treat it as an object
        for child in children:
            if child.kind() in {xnText, xnVerbatimText}:
                result = newJString(child.text)
            elif child.kind() == xnElement:
                if child.hasEscapedChar():
                    result[child.tag()] = newJString(child.getUnescapedString())
                elif result.hasKey(child.tag()):
                    # assume it is an array
                    if result[child.tag()].kind != JArray:
                        let tempArray = newJArray()
                        tempArray.add(result[child.tag()])
                        result[child.tag()] = tempArray
                    result[child.tag()].add(child.xml2Json(splitAttr, false))
                else:
                    # assume it is an object
                    result[child.tag()] = child.xml2Json(splitAttr, false)      
            else:
                raise newException(ValueError, "kind not implemented: " & $child.kind())
    of xnComment:
        result = newJObject()
        result["comment"] = newJString(xmlNode.text)
    of xnCData:
        result = newJObject()
        result["cdata"] = newJString(xmlNode.text)
    of xnEntity:
        result = newJObject()
        result["entity"] = newJString(xmlNode.text)

suite "xml2Json":
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