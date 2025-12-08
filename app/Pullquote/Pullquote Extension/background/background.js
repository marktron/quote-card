import { ErrorCode } from "../shared/errors.js";
function formatNativeError(error) {
    if (error.message.includes("not found")) {
        return "Native app not running. Please open the Pullquote app.";
    }
    if (error.message.includes("disconnected")) {
        return "Lost connection to native app. Please restart Pullquote.";
    }
    return `Native messaging error: ${error.message}`;
}
function relayToNative(message, sendResponse, errorResponse) {
    browser.runtime
        .sendNativeMessage("application.id", message)
        .then((response) => {
        sendResponse(response);
    })
        .catch((error) => {
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
browser.runtime.onMessage.addListener((message, _sender, sendResponse) => {
    if (message.type === "RENDER_REQUEST") {
        relayToNative(message, sendResponse, {
            id: message.payload.id,
            success: false
        });
        return true;
    }
    if (message.type === "COPY_REQUEST") {
        relayToNative(message, sendResponse, { success: false });
        return true;
    }
    return false;
});
