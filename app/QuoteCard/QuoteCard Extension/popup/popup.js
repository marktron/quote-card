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
const themePicker = document.querySelector(".theme-picker");
const formatPicker = document.querySelector(".format-picker");
const formatButtons = document.querySelectorAll(".format-btn");
const copyBtn = document.getElementById("copy-btn");
const saveBtn = document.getElementById("save-btn");
const closeBtn = document.getElementById("close-btn");
const retryBtn = document.getElementById("retry-btn");
// Current state
let currentThemeId = "minimalist";
let currentAspectRatio = "portrait";
let formatPickerExpanded = false;
// State
let currentRequest = null;
let currentResult = null;
let activeTabId = null;
let allThemesUnlocked = false;
let themesData = [];
let currentThemeIsLocked = false;
function getThemeBackground(theme) {
    const bg = theme.background;
    if (bg.type === "gradient" && bg.gradient) {
        const colors = bg.gradient.colors;
        const direction = bg.gradient.direction === "horizontal" ? "to right" : "to bottom";
        return `linear-gradient(${direction}, ${colors.join(", ")})`;
    }
    if (bg.type === "image" && bg.image) {
        const imageUrl = browser.runtime.getURL(bg.image.url);
        return `url('${imageUrl}') center/cover, ${bg.color || "#888"}`;
    }
    return bg.color || "#888";
}
function setActiveTheme(themeId) {
    currentThemeId = themeId;
    themePicker.querySelectorAll(".theme-swatch").forEach(btn => {
        btn.classList.toggle("active", btn.dataset.theme === themeId);
    });
}
function isThemeUnlocked(theme) {
    return theme.free || allThemesUnlocked;
}
async function checkPurchaseStatus() {
    try {
        // Check purchase status via native messaging directly
        const response = await browser.runtime.sendNativeMessage("application.id", // Safari ignores this, uses the containing app
        { type: "CHECK_PURCHASE_STATUS" });
        if (response?.allThemesUnlocked !== undefined) {
            allThemesUnlocked = response.allThemesUnlocked;
            // Cache in storage for faster subsequent checks
            await browser.storage.local.set({ allThemesUnlocked });
        }
    }
    catch {
        // Fall back to cached status
        const storage = await browser.storage.local.get(["allThemesUnlocked"]);
        if (storage.allThemesUnlocked) {
            allThemesUnlocked = true;
        }
    }
}
function updateButtonState() {
    const actionsContainer = document.querySelector(".actions");
    if (!actionsContainer)
        return;
    if (currentThemeIsLocked) {
        // Hide normal buttons, show unlock button
        copyBtn.classList.add("hidden");
        saveBtn.classList.add("hidden");
        // Add unlock button if not already there
        let unlockBtn = document.getElementById("unlock-btn");
        if (!unlockBtn) {
            unlockBtn = document.createElement("button");
            unlockBtn.id = "unlock-btn";
            unlockBtn.className = "btn btn-primary unlock-btn";
            unlockBtn.innerHTML = '🔓 Unlock All Themes';
            unlockBtn.addEventListener("click", () => {
                openQuoteCardApp();
            });
            actionsContainer.appendChild(unlockBtn);
        }
        unlockBtn.classList.remove("hidden");
    }
    else {
        // Show normal buttons, hide unlock button
        copyBtn.classList.remove("hidden");
        saveBtn.classList.remove("hidden");
        const unlockBtn = document.getElementById("unlock-btn");
        if (unlockBtn) {
            unlockBtn.classList.add("hidden");
        }
    }
}
function openQuoteCardApp() {
    window.open("quotecard://unlock", "_self");
}
async function populateThemeSelector() {
    try {
        const response = await fetch(browser.runtime.getURL("shared/themes.json"));
        const data = await response.json();
        themesData = data.themes;
        themePicker.innerHTML = "";
        // Use original order from themes.json
        data.themes.forEach(theme => {
            const swatch = document.createElement("button");
            swatch.type = "button";
            swatch.className = "theme-swatch";
            swatch.dataset.theme = theme.id;
            const isLocked = !isThemeUnlocked(theme);
            if (isLocked) {
                swatch.classList.add("locked");
                swatch.dataset.tooltip = `${theme.name} (Locked)`;
            }
            else {
                swatch.dataset.tooltip = theme.name;
            }
            swatch.setAttribute("aria-label", theme.name);
            // Set background
            swatch.style.background = getThemeBackground(theme);
            // Set font styling for "Aa" text
            swatch.style.fontFamily = `${theme.font.family}, ${theme.font.fallback}`;
            swatch.style.fontWeight = String(theme.font.weight);
            swatch.style.color = theme.text.color;
            // Add lock icon for locked themes, "Aa" for unlocked
            if (isLocked) {
                swatch.innerHTML = '<span class="lock-icon">🔒</span>';
            }
            else {
                swatch.textContent = "Aa";
            }
            // Add click handler - allow selecting locked themes but track state
            swatch.addEventListener("click", () => {
                currentThemeIsLocked = !isThemeUnlocked(theme);
                setActiveTheme(theme.id);
                updateButtonState();
                void handleControlChange();
            });
            themePicker.appendChild(swatch);
        });
    }
    catch (error) {
        console.error("Failed to load themes:", error);
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
        const cardPreview = getCardPreview();
        cardPreview.innerHTML = "";
        if (currentThemeIsLocked) {
            // Use background-image div to prevent right-click saving
            const previewDiv = document.createElement("div");
            previewDiv.className = "preview-image-locked";
            previewDiv.style.backgroundImage = `url(${result.dataUrl})`;
            cardPreview.appendChild(previewDiv);
        }
        else {
            // Normal img element for unlocked themes
            const img = document.createElement("img");
            img.src = result.dataUrl;
            img.alt = "Quote card preview";
            cardPreview.appendChild(img);
        }
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
function setActiveFormat(format) {
    currentAspectRatio = format;
    formatButtons.forEach(btn => {
        const btnFormat = btn.dataset.format;
        btn.classList.toggle("active", btnFormat === format);
    });
}
function expandFormatPicker() {
    formatPickerExpanded = true;
    formatPicker.classList.add("expanded");
}
function collapseFormatPicker() {
    formatPickerExpanded = false;
    formatPicker.classList.remove("expanded");
}
async function handleControlChange() {
    if (!currentRequest)
        return;
    const prefs = {
        themeId: currentThemeId,
        aspectRatio: currentAspectRatio
    };
    const settings = {
        themeId: currentThemeId,
        aspectRatio: currentAspectRatio,
        exportFormat: "jpeg",
        includeAttribution: true
    };
    currentRequest.settingsOverride = settings;
    await browser.storage.sync.set({ userPreferences: prefs });
    await renderQuoteCard(true);
}
async function handleFormatChange(format) {
    setActiveFormat(format);
    await handleControlChange();
}
async function init() {
    try {
        setState("loading");
        // Check purchase status FIRST, before populating themes
        await checkPurchaseStatus();
        await populateThemeSelector();
        // Check if opened from context menu (tab ID stored in session storage)
        let tabId;
        const sessionData = await browser.storage.session.get(["contextMenuTabId"]);
        if (sessionData.contextMenuTabId) {
            tabId = sessionData.contextMenuTabId;
            // Clear it so it's not reused
            await browser.storage.session.remove("contextMenuTabId");
        }
        else {
            // Normal popup - get active tab
            const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
            if (!tab?.id) {
                setState("error", browser.i18n.getMessage("errorTabAccess") || "Could not access current tab");
                return;
            }
            tabId = tab.id;
        }
        activeTabId = tabId;
        let selectionResp;
        try {
            selectionResp = await browser.tabs.sendMessage(tabId, {
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
        if (!selectionResp?.text) {
            setState("empty");
            return;
        }
        const storage = await browser.storage.sync.get(["userPreferences"]);
        const prefs = storage.userPreferences || {
            themeId: "minimalist",
            aspectRatio: "portrait"
        };
        // If selected theme is locked, fall back to minimalist
        const selectedTheme = themesData.find(t => t.id === prefs.themeId);
        if (selectedTheme && !isThemeUnlocked(selectedTheme)) {
            prefs.themeId = "minimalist";
        }
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
        setActiveTheme(prefs.themeId);
        setActiveFormat(prefs.aspectRatio);
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
// Format picker expand/collapse behavior
formatButtons.forEach(btn => {
    btn.addEventListener("click", (e) => {
        e.stopPropagation();
        const format = btn.dataset.format;
        if (!formatPickerExpanded) {
            // Collapsed: expand the picker
            expandFormatPicker();
        }
        else {
            // Expanded: select format and collapse
            if (format && format !== currentAspectRatio) {
                void handleFormatChange(format);
            }
            collapseFormatPicker();
        }
    });
});
// Collapse format picker when clicking outside
document.addEventListener("click", (e) => {
    if (formatPickerExpanded && !formatPicker.contains(e.target)) {
        collapseFormatPicker();
    }
});
copyBtn.addEventListener("click", () => void copyToClipboard());
saveBtn.addEventListener("click", () => void saveImage());
closeBtn.addEventListener("click", () => window.close());
retryBtn.addEventListener("click", () => window.close());
// Initialize
void init();
