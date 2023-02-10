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

proc xml2Json*(xmlNode: XmlNode, splitAttr: bool=false): JsonNode =
    ## Convert an XML node to a JSON node.
    ## if <Element><Element> the resulting json will be JSNull
    ## if <Element>1000</Element> the resulting json will be JSString not JSInt
    if xmlNode.tag == "UploadIdMarker":
        echo "here"

    case xmlNode.kind():
    of xnVerbatimText, xnText:
        result = newJString(xmlNode.text)
    of xnElement:
        let children = xmlNode.items().toSeq()
        if children.len == 0:
            return newJNull()
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
                if result.hasKey(child.tag()):
                    # assume it is an array
                    if result[child.tag()].kind != JArray:
                        let tempArray = newJArray()
                        tempArray.add(result[child.tag()])
                        result[child.tag()] = tempArray
                    result[child.tag()].add(child.xml2Json(splitAttr))
                else:
                    # assume it is an object
                    result[child.tag()] = child.xml2Json(splitAttr)      
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
        Xml2JsonTest = object
            id: string
            child1: string
            child2: seq[string]
            child3: Table[string, string]
            child5: string

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

    test "xml->jsonString":
        let xml = xmlString.parseXml()
        let expectedJson = """{"id":"123","child1":"value1","child2":["value2","value3"],"child3":{"child4":"value4"},"Child5":"value5"}"""
        let expectedJsonSplitAttr = """{"attributes":{"id":"123"},"child1":"value1","child2":["value2","value3"],"child3":{"child4":"value4"},"Child5":"value5"}"""
        check:
            $xml.xml2Json() == expectedJson
            $xml.xml2Json(true) == expectedJsonSplitAttr

    test "xml->json->obj":

        let xml = xmlString.parseXml()
        let json = xml.xml2Json()
        let jsonString = json.toJson()
        let obj = jsonString.fromJson(Xml2JsonTest)
        let expectedObject = Xml2JsonTest(
            id: "123",
            child1: "value1",
            child2: @["value2", "value3"],
            child3: {"child4": "value4"}.toTable(),
            child5: "value5"
        )
        echo jsonString
        check:

            obj == expectedObject