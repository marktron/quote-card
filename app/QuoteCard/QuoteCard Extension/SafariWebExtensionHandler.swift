//
//  SafariWebExtensionHandler.swift
//  QuoteCard Extension
//
//  Created by Mark Allen on 2025-12-04.
//

import SafariServices
import AppKit

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        Task {
            await handleMessage(message: message, context: context)
        }
    }

    private func handleMessage(message: Any?, context: NSExtensionContext) async {
        guard let messageDict = message as? [String: Any],
              let type = messageDict["type"] as? String else {
            sendResponse(["error": "Invalid message format"], context: context)
            return
        }

        switch type {
        case "RENDER_REQUEST":
            await handleRenderRequest(messageDict: messageDict, context: context)
        case "COPY_REQUEST":
            handleCopyRequest(messageDict: messageDict, context: context)
        default:
            sendResponse(["error": "Unknown message type"], context: context)
        }
    }

    private func handleCopyRequest(messageDict: [String: Any], context: NSExtensionContext) {
        guard let payloadDict = messageDict["payload"] as? [String: Any],
              let dataUrl = payloadDict["dataUrl"] as? String else {
            sendResponse(["success": false, "errorMessage": "Missing dataUrl"], context: context)
            return
        }

        // Parse data URL to extract base64 image data
        guard let commaIndex = dataUrl.firstIndex(of: ",") else {
            sendResponse(["success": false, "errorMessage": "Invalid data URL format"], context: context)
            return
        }

        let base64String = String(dataUrl[dataUrl.index(after: commaIndex)...])

        guard let imageData = Data(base64Encoded: base64String),
              let image = NSImage(data: imageData) else {
            sendResponse(["success": false, "errorMessage": "Failed to decode image"], context: context)
            return
        }

        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.writeObjects([image])

        sendResponse(["success": success], context: context)
    }

    private func handleRenderRequest(messageDict: [String: Any], context: NSExtensionContext) async {
        guard let payloadDict = messageDict["payload"] as? [String: Any] else {
            sendResponse(["error": "Missing payload"], context: context)
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payloadDict)
            let renderRequest = try JSONDecoder().decode(RenderRequest.self, from: jsonData)
            let result = await QuoteCardRenderer.shared.render(request: renderRequest)
            let resultData = try JSONEncoder().encode(result)
            let resultDict = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]

            sendResponse(resultDict, context: context)
        } catch {
            sendResponse([
                "id": payloadDict["id"] as? String ?? "",
                "success": false,
                "errorMessage": error.localizedDescription
            ], context: context)
        }
    }

    private func sendResponse(_ response: [String: Any], context: NSExtensionContext) {
        let responseItem = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            responseItem.userInfo = [SFExtensionMessageKey: response]
        } else {
            responseItem.userInfo = ["message": response]
        }
        context.completeRequest(returningItems: [responseItem], completionHandler: nil)
    }
}
