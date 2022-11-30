//
//  NSItemProvider+Extensions.swift
//  RNShareMenu
//
//  Created by Gustavo Parreira on 29/07/2020.
//

import MobileCoreServices

public extension NSItemProvider {
    var isText: Bool {
        return hasItemConformingToTypeIdentifier("public.plain-text")
    }

    var isURL: Bool {
        return hasItemConformingToTypeIdentifier("public.url") && !isFileURL
    }

    var isFileURL: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeFileURL as String)
    }
}
