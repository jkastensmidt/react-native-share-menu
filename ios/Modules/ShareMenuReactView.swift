//
//  ShareMenuReactView.swift
//  RNShareMenu
//
//  Created by Gustavo Parreira on 28/07/2020.
//  Modified by Veselin Stoyanov on 17/04/2021.

import Foundation
import MobileCoreServices

@objc(ShareMenuReactView)
public class ShareMenuReactView: NSObject {
    static var viewDelegate: ReactShareViewDelegate?

    @objc
    static public func requiresMainQueueSetup() -> Bool {
        return false
    }

    public static func attachViewDelegate(_ delegate: ReactShareViewDelegate!) {
//         guard (ShareMenuReactView.viewDelegate == nil) else { return }

        ShareMenuReactView.viewDelegate = delegate
    }

    public static func detachViewDelegate() {
        ShareMenuReactView.viewDelegate = nil
    }

    @objc(dismissExtension:)
    func dismissExtension(_ error: String?) {
        guard let extensionContext = ShareMenuReactView.viewDelegate?.loadExtensionContext() else {
            print("Error: \(NO_EXTENSION_CONTEXT_ERROR)")
            return
        }

        if error != nil {
            let exception = NSError(
                domain: Bundle.main.bundleIdentifier!,
                code: DISMISS_SHARE_EXTENSION_WITH_ERROR_CODE,
                userInfo: ["error": error!]
            )
            extensionContext.cancelRequest(withError: exception)
            return
        }

        extensionContext.completeRequest(returningItems: [], completionHandler: nil)
    }

    @objc
    func openApp() {
        guard let viewDelegate = ShareMenuReactView.viewDelegate else {
            print("Error: \(NO_DELEGATE_ERROR)")
            return
        }

        viewDelegate.openApp()
    }

    @objc(continueInApp:)
    func continueInApp(_ extraData: [String:Any]?) {
        guard let viewDelegate = ShareMenuReactView.viewDelegate else {
            print("Error: \(NO_DELEGATE_ERROR)")
            return
        }

        let extensionContext = viewDelegate.loadExtensionContext()

        guard let items = extensionContext.inputItems as? [NSExtensionItem] else {
            print("Error: \(COULD_NOT_FIND_ITEMS_ERROR)")
            return
        }

        viewDelegate.continueInApp(with: items, and: extraData)
    }

    @objc(data:reject:)
    func data(_
            resolve: @escaping RCTPromiseResolveBlock,
            reject: @escaping RCTPromiseRejectBlock) {
        guard let extensionContext = ShareMenuReactView.viewDelegate?.loadExtensionContext() else {
            print("Error: \(NO_EXTENSION_CONTEXT_ERROR)")
            return
        }

        // var urlFound = "Nonefound";
        // if let item = extensionContext.inputItems.first as? NSExtensionItem {
        //     if let itemProvider = item.attachments?.first as? NSItemProvider {
        //         if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
        //             itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, error) -> Void in
        //                 if let shareURL = url as? NSURL {
        //                     // send url to server to share the link
        //                     print("AWESOME URL HERE",shareURL)
        //                 urlFound = shareURL.absoluteString ?? "StillNoneFound!"
        //                 }
        //                 resolve([MIME_TYPE_KEY: "text/plain", DATA_KEY: urlFound])
        //             })
        //         }
        //     }
        // }

        extractDataFromContext(context: extensionContext) { (data, error) in
            guard (error == nil) else {
                reject("error", error?.description, nil)
                return
            }

            resolve([DATA_KEY: data])
        }
    }

    func extractDataFromContext(context: NSExtensionContext, withCallback callback: @escaping ([Any]?, NSException?) -> Void) {
        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            let items:[NSExtensionItem]! = context.inputItems as? [NSExtensionItem]
            var results: [[String: String]] = []
            
            NSLog("Test")
            print("items",items)
            NSLog("items",items)

            for item in items {
                
                guard let providers = item.attachments else {
                    callback(nil, NSException(name: NSExceptionName(rawValue: "Error"), reason:"couldn't find attachments", userInfo:nil))
                    return
                }

                print("providers", providers)

                for provider in providers {
                    if provider.hasItemConformingToTypeIdentifier("public.url") {
                        provider.loadItem(forTypeIdentifier: "public.url", options: nil) { (item, error) in
                            if error == nil {
                                if let url = item as? URL {
                                    results.append([DATA_KEY: url.absoluteString, MIME_TYPE_KEY: "text/plain"])
                                }
                            }
                            semaphore.signal()
                        }
                        semaphore.wait()
                    } else if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                        provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { (item, error) in
                            if error == nil {
                                if let text = item as? String {
                                    results.append([DATA_KEY: text, MIME_TYPE_KEY: "text/plain"])
                                }
                            }
                            semaphore.signal()
                        }
                        semaphore.wait()
                    }  else {
                        continue
                    }
                }
            }

            callback(results, nil)
        }
    }

    func extractMimeType(from url: URL) -> String {
      let fileExtension: CFString = url.pathExtension as CFString
      guard let extUTI = UTTypeCreatePreferredIdentifierForTag(
              kUTTagClassFilenameExtension,
              fileExtension,
              nil
      )?.takeUnretainedValue() else { return "" }

      guard let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI, kUTTagClassMIMEType)
      else { return "" }

      return mimeUTI.takeUnretainedValue() as String
    }
}
