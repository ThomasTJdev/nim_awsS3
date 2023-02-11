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


# type
#   XmlNode* = ref XmlNodeObj ## An XML tree consisting of XML nodes.
#     ##
#     ## Use `newXmlTree proc <#newXmlTree,string,openArray[XmlNode],XmlAttributes>`_
#     ## for creating a new tree.

#   XmlNodeKind* = enum ## Different kinds of XML nodes.
#     xnText,           ## a text element
#     xnVerbatimText,   ##
#     xnElement,        ## an element with 0 or more children
#     xnCData,          ## a CDATA node
#     xnEntity,         ## an entity (like ``&thing;``)
#     xnComment         ## an XML comment

#   XmlAttributes* = StringTableRef ## An alias for a string to string mapping.
#     ##
#     ## Use `toXmlAttributes proc <#toXmlAttributes,varargs[tuple[string,string]]>`_
#     ## to create `XmlAttributes`.

#   XmlNodeObj {.acyclic.} = object
#     case k: XmlNodeKind # private, use the kind() proc to read this field.
#     of xnText, xnVerbatimText, xnComment, xnCData, xnEntity:
#       fText: string
#     of xnElement:
#       fTag: string
#       s: seq[XmlNode]
#       fAttr: XmlAttributes
#     fClientData: int    ## for other clients


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

    if isFrist:
        result = newJObject()
        result[xmlNode.tag()] = xmlNode.xml2Json(splitAttr, false)
        return result
    case xmlNode.kind():
    of xnVerbatimText, xnText:
        result = newJString(xmlNode.text)
    of xnElement:
        let children = xmlNode.items().toSeq()
        if children.len == 0:
            return newJNull()
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
        # if it has children and tags that are the same it is an array
        for child in children:
            if child.kind() in {xnText, xnVerbatimText}:
                result = newJString(child.text)
            elif child.kind() == xnElement:
                if child.hasEscapedChar():
                    echo child.tag()
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

# todo if start to upload multiple xml bodys
# proc json2xml(jsNode: JsonNode, jsKey: string=""): XmlNode=
#     case jsNode.kind:
#     of JString:
#         result = newText(jsNode.getStr)
#     of JInt:
#         result = newText($jsNode.getInt)
#     of JFloat:
#         result = newText($jsNode.getFloat)
#     of JBool:
#         result = newText($jsNode.getBool)
#     of JNull:
#         result = newText("")
#     of JObject:
#         result = newElement(if jsKey == "": "root" else: jsKey)
#         for key, val in jsNode.getFields():
#             if val.kind == JArray:
#                 for item in val.elems:
#                     var child = newElement(key)
#                     child.add(item.json2xml(key))
#                     result.add(child)
#             # elif val.kind == JObject:
#             else:
#                 var child = newElement(key)
#                 child.add(val.json2xml())
#                 result.add(child)

#     of JArray:
#         result = newElement(if jsKey == "": "root" else: jsKey)
#         for val in jsNode.elems:
#             result.add(val.json2xml())
   
            

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

    # test "json->xml":
    #     let json = expectedJson.parseJson()
    #     echo json.pretty()
    #     echo json.json2xml()

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
        # echo n0.items().toSeq()
        # echo n0.hasEscapedChar()
        # echo $n0
        let root = newElement("root")
        root.add(n0)

        check:
            n0.xml2Json().toJson() == expectedJson
            root.xml2Json().toJson() == expectedJson1

    test "jsony object":
        let json = """{"Xml2JsonTestRoot":{"id":"123","child1":"value1","child2":["value2","value3"],"child3":{"child4":"value4"},"Child5":"value5"}}"""
        let obj = json.parseJson()["Xml2JsonTestRoot"].toJson().fromJson(Xml2JsonTestRoot)
        echo obj