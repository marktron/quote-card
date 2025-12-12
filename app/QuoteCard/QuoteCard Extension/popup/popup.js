import { isConnectionError } from "../shared/errors.js";
import { initUI, setState, getCardPreview, withButtonState } from "./ui.js";
// Localization - call browser.i18n.getMessage directly to avoid Safari's strict mode binding issue
function localizeDocument() {
    document.querySelectorAll("[data-i18n]").forEach(element => {
        const key = element.getAttribute("data-i18n");
        if (key) {
            const message = browser.i18n.getMessage(key);
            if (message) {
                element.textContent = message;
            }
        }
    });
}
// Initialize UI elements
initUI();
localizeDocument();
const themeSelect = document.getElementById("theme-select");
const aspectSelect = document.getElementById("aspect-select");
const copyBtn = document.getElementById("copy-btn");
const saveBtn = document.getElementById("save-btn");
const closeBtn = document.getElementById("close-btn");
const retryBtn = document.getElementById("retry-btn");
// State
let currentRequest = null;
let currentResult = null;
let activeTabId = null;
async function populateThemeSelector() {
    try {
        const response = await fetch(browser.runtime.getURL("shared/themes.json"));
        const data = await response.json();
        themeSelect.innerHTML = "";
        const themesArray = data.themes.sort((a, b) => a.name.localeCompare(b.name));
        themesArray.forEach(theme => {
            const option = document.createElement("option");
            option.value = theme.id;
            option.textContent = theme.name;
            option.title = theme.description;
            themeSelect.appendChild(option);
        });
    }
    catch (error) {
        console.error("Failed to load themes:", error);
        const option = document.createElement("option");
        option.value = "scholarly";
        option.textContent = "Scholarly";
        themeSelect.appendChild(option);
    }
}
async function callNativeRenderer(request) {
    if (!activeTabId) {
        throw new Error("No active tab ID available");
    }
    const response = await browser.tabs.sendMessage(activeTabId, {
        type: "RENDER_REQUEST_RELAY",
        payload: request
    });
    if (!response || !response.success) {
        return {
            id: request.id,
            success: false,
            errorMessage: response?.errorMessage || "Native renderer failed"
        };
    }
    return response;
}
async function renderQuoteCard(isRerender = false) {
    if (!currentRequest)
        return;
    try {
        setState(isRerender ? "cardLoading" : "loading");
        const result = await callNativeRenderer(currentRequest);
        currentResult = result;
        if (!result.success || !result.dataUrl) {
            setState("error", result.errorMessage || browser.i18n.getMessage("errorRenderFailed") || "Failed to render quote card");
            return;
        }
        const img = document.createElement("img");
        img.src = result.dataUrl;
        img.alt = "Quote card preview";
        const cardPreview = getCardPreview();
        cardPreview.innerHTML = "";
        cardPreview.appendChild(img);
        setState("preview");
    }
    catch (error) {
        console.error("Render error:", error);
        setState("error", browser.i18n.getMessage("errorRenderFailed") || "Failed to render quote card");
    }
}
async function copyToClipboard() {
    if (!currentResult?.dataUrl || !activeTabId)
        return;
    const dataUrl = currentResult.dataUrl;
    const tabId = activeTabId;
    await withButtonState(copyBtn, async () => {
        const response = await browser.tabs.sendMessage(tabId, {
            type: "COPY_REQUEST_RELAY",
            payload: { dataUrl }
        });
        return response;
    }, {
        loading: browser.i18n.getMessage("copyingButton") || "Copying...",
        success: browser.i18n.getMessage("copiedButton") || "Copied!",
        initial: browser.i18n.getMessage("copyButton") || "Copy to Clipboard"
    }, response => {
        if (!response?.success) {
            const errorMsg = browser.i18n.getMessage("errorCopyFailed") || "Failed to copy to clipboard";
            alert(`${errorMsg}: ${response?.errorMessage || ""}`);
            return false;
        }
        return true;
    });
}
async function saveImage() {
    if (!currentResult?.dataUrl || !activeTabId)
        return;
    const dataUrl = currentResult.dataUrl;
    const sourceTitle = currentRequest?.sourceTitle;
    const tabId = activeTabId;
    await withButtonState(saveBtn, async () => {
        const response = await browser.tabs.sendMessage(tabId, {
            type: "SAVE_REQUEST_RELAY",
            payload: { dataUrl, sourceTitle }
        });
        return response;
    }, {
        loading: browser.i18n.getMessage("savingButton") || "Saving...",
        success: browser.i18n.getMessage("savedButton") || "Saved!",
        initial: browser.i18n.getMessage("downloadButton") || "Download"
    }, response => {
        if (!response?.success) {
            const errorMsg = browser.i18n.getMessage("errorSaveFailed") || "Failed to save image";
            alert(`${errorMsg}: ${response?.errorMessage || ""}`);
            return false;
        }
        return true;
    }, 2500);
}
async function handleControlChange() {
    if (!currentRequest)
        return;
    const prefs = {
        themeId: themeSelect.value,
        aspectRatio: aspectSelect.value
    };
    const settings = {
        themeId: prefs.themeId,
        aspectRatio: prefs.aspectRatio,
        exportFormat: "jpeg",
        includeAttribution: true
    };
    currentRequest.settingsOverride = settings;
    await browser.storage.sync.set({ userPreferences: prefs });
    await renderQuoteCard(true);
}
async function init() {
    try {
        setState("loading");
        await populateThemeSelector();
        const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
        if (!tab?.id) {
            setState("error", browser.i18n.getMessage("errorTabAccess") || "Could not access current tab");
            return;
        }
        activeTabId = tab.id;
        let selectionResp;
        try {
            selectionResp = await browser.tabs.sendMessage(tab.id, {
                type: "REQUEST_SELECTION"
            });
        }
        catch (error) {
            if (isConnectionError(error)) {
                setState("error", browser.i18n.getMessage("errorConnection") || "Please reload the page and try again");
                return;
            }
            throw error;
        }
        if (!selectionResp || !selectionResp.text) {
            setState("empty");
            return;
        }
        const storage = await browser.storage.sync.get(["userPreferences"]);
        const prefs = storage.userPreferences || {
            themeId: "scholarly",
            aspectRatio: "portrait"
        };
        const settings = {
            themeId: prefs.themeId,
            aspectRatio: prefs.aspectRatio,
            exportFormat: "jpeg",
            includeAttribution: true
        };
        currentRequest = {
            id: crypto.randomUUID(),
            text: selectionResp.text,
            html: selectionResp.html,
            sourceTitle: selectionResp.sourceTitle,
            sourceUrl: selectionResp.sourceUrl,
            faviconUrl: selectionResp.faviconUrl,
            createdAt: Date.now(),
            settingsOverride: settings
        };
        themeSelect.value = prefs.themeId;
        aspectSelect.value = prefs.aspectRatio;
        await renderQuoteCard();
    }
    catch (error) {
        if (isConnectionError(error)) {
            setState("error", browser.i18n.getMessage("errorConnection") || "Please reload the page and try again");
        }
        else {
            console.error("Popup initialization error:", error);
            setState("error", browser.i18n.getMessage("errorUnexpected") || "An unexpected error occurred");
        }
    }
}
// Event listeners - wrap async handlers to avoid unhandled promise warnings
themeSelect.addEventListener("change", () => void handleControlChange());
aspectSelect.addEventListener("change", () => void handleControlChange());
copyBtn.addEventListener("click", () => void copyToClipboard());
saveBtn.addEventListener("click", () => void saveImage());
closeBtn.addEventListener("click", () => window.close());
retryBtn.addEventListener("click", () => window.close());
// Initialize
void init();
