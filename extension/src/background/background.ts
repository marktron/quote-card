import type { ExtensionMessage, RenderResult, CopyResult } from "../shared/types.js";
import { ErrorCode } from "../shared/errors.js";

type NativeMessageType = "RENDER_REQUEST" | "COPY_REQUEST";

interface NativeMessage {
  type: NativeMessageType;
  payload: unknown;
}

function formatNativeError(error: Error): string {
  if (error.message.includes("not found")) {
    return "Native app not running. Please open the Pullquote app.";
  }
  if (error.message.includes("disconnected")) {
    return "Lost connection to native app. Please restart Pullquote.";
  }
  return `Native messaging error: ${error.message}`;
}

function relayToNative<T>(
  message: NativeMessage,
  sendResponse: (response: T) => void,
  errorResponse: T
): void {
  browser.runtime
    .sendNativeMessage("application.id", message)
    .then((response: T) => {
      sendResponse(response);
    })
    .catch((error: Error) => {
      console.error(`[${ErrorCode.NATIVE_MESSAGING}]`, error.message);
      sendResponse({
        ...errorResponse,
        errorMessage: formatNativeError(error)
      });
    });
}

/**
 * Relay requests from content scripts to native Swift code
 *
 * In Safari, browser.runtime.sendNativeMessage() can ONLY be called
 * from the background script, not from content scripts.
 */
browser.runtime.onMessage.addListener(
  (
    message: ExtensionMessage,
    _sender: chrome.runtime.MessageSender,
    sendResponse: (response: unknown) => void
  ) => {
    if (message.type === "RENDER_REQUEST") {
      relayToNative<RenderResult>(message, sendResponse, {
        id: message.payload.id,
        success: false
      });
      return true;
    }

    if (message.type === "COPY_REQUEST") {
      relayToNative<CopyResult>(message, sendResponse, { success: false });
      return true;
    }

    return false;
  }
);
