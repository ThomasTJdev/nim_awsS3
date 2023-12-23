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
