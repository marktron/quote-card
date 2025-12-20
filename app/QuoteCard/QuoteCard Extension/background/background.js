import { ErrorCode } from "../shared/errors.js";
const CONTEXT_MENU_ID = "create-quotecard";
/**
 * Create the context menu item for text selection
 */
function createContextMenu() {
    browser.contextMenus.create({
        id: CONTEXT_MENU_ID,
        title: "Create QuoteCard",
        contexts: ["selection"]
    }, () => {
        // Check for errors during creation
        if (browser.runtime.lastError) {
            console.error("Context menu creation error:", browser.runtime.lastError);
        }
    });
}
/**
 * Handle context menu item click - opens the popup in a new window
 * We always use the window approach because browser.action.openPopup()
 * silently fails when the toolbar button isn't visible in Safari
 */
browser.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId !== CONTEXT_MENU_ID)
        return;
    if (!tab?.id)
        return;
    // Store the tab ID so the popup can access it
    void browser.storage.session.set({ contextMenuTabId: tab.id });
    // Open popup.html in a new tab instead (Safari doesn't support popup windows well)
    void browser.tabs.create({
        url: browser.runtime.getURL("popup/popup.html"),
        active: true
    });
});
// Create context menu on extension install/update
browser.runtime.onInstalled.addListener(() => {
    createContextMenu();
});
// Also create on startup (in case it wasn't persisted)
browser.runtime.onStartup.addListener(() => {
    createContextMenu();
});
function formatNativeError(error) {
    if (error.message.includes("not found")) {
        return "Native app not running. Please open the QuoteCard app.";
    }
    if (error.message.includes("disconnected")) {
        return "Lost connection to native app. Please restart QuoteCard.";
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
