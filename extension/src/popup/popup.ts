import type {
  RenderRequest,
  RenderResult,
  RenderSettings,
  ThemesData,
  AspectRatio
} from "../shared/types.js";
import { isConnectionError } from "../shared/errors.js";
import { initUI, setState, getCardPreview, withButtonState } from "./ui.js";

// Initialize UI elements
initUI();
const themeSelect = document.getElementById("theme-select") as HTMLSelectElement;
const aspectSelect = document.getElementById("aspect-select") as HTMLSelectElement;
const copyBtn = document.getElementById("copy-btn") as HTMLButtonElement;
const saveBtn = document.getElementById("save-btn") as HTMLButtonElement;
const closeBtn = document.getElementById("close-btn") as HTMLButtonElement;
const retryBtn = document.getElementById("retry-btn") as HTMLButtonElement;

// State
let currentRequest: RenderRequest | null = null;
let currentResult: RenderResult | null = null;
let activeTabId: number | null = null;

async function populateThemeSelector(): Promise<void> {
  try {
    const response = await fetch(browser.runtime.getURL("shared/themes.json"));
    const data: ThemesData = await response.json();

    themeSelect.innerHTML = "";

    const themesArray = data.themes.sort((a, b) => a.name.localeCompare(b.name));

    themesArray.forEach(theme => {
      const option = document.createElement("option");
      option.value = theme.id;
      option.textContent = theme.name;
      option.title = theme.description;
      themeSelect.appendChild(option);
    });
  } catch (error) {
    console.error("Failed to load themes:", error);
    const option = document.createElement("option");
    option.value = "scholarly";
    option.textContent = "Scholarly";
    themeSelect.appendChild(option);
  }
}

async function callNativeRenderer(request: RenderRequest): Promise<RenderResult> {
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

  return response as RenderResult;
}

async function renderQuoteCard(isRerender = false): Promise<void> {
  if (!currentRequest) return;

  try {
    setState(isRerender ? "cardLoading" : "loading");

    const result = await callNativeRenderer(currentRequest);
    currentResult = result;

    if (!result.success || !result.dataUrl) {
      setState("error", result.errorMessage || "Rendering failed");
      return;
    }

    const img = document.createElement("img");
    img.src = result.dataUrl;
    img.alt = "Quote card preview";

    const cardPreview = getCardPreview();
    cardPreview.innerHTML = "";
    cardPreview.appendChild(img);

    setState("preview");
  } catch (error) {
    console.error("Render error:", error);
    setState("error", "Failed to render quote card");
  }
}

async function copyToClipboard(): Promise<void> {
  if (!currentResult?.dataUrl || !activeTabId) return;

  const dataUrl = currentResult.dataUrl;
  const tabId = activeTabId;

  await withButtonState(
    copyBtn,
    async () => {
      const response = await browser.tabs.sendMessage(tabId, {
        type: "COPY_REQUEST_RELAY",
        payload: { dataUrl }
      });
      return response;
    },
    { loading: "Copying...", success: "Copied!", initial: "Copy to Clipboard" },
    response => {
      if (!response?.success) {
        alert(`Failed to copy: ${response?.errorMessage || "Unknown error"}`);
        return false;
      }
      return true;
    }
  );
}

async function saveImage(): Promise<void> {
  if (!currentResult?.dataUrl || !activeTabId) return;

  const dataUrl = currentResult.dataUrl;
  const sourceTitle = currentRequest?.sourceTitle;
  const tabId = activeTabId;

  await withButtonState(
    saveBtn,
    async () => {
      const response = await browser.tabs.sendMessage(tabId, {
        type: "SAVE_REQUEST_RELAY",
        payload: { dataUrl, sourceTitle }
      });
      return response;
    },
    { loading: "Saving...", success: "Saved to Downloads!", initial: "Save Image" },
    response => {
      if (!response?.success) {
        alert(`Failed to save: ${response?.errorMessage || "Unknown error"}`);
        return false;
      }
      return true;
    },
    2500
  );
}

async function handleControlChange(): Promise<void> {
  if (!currentRequest) return;

  const prefs = {
    themeId: themeSelect.value,
    aspectRatio: aspectSelect.value
  };

  const settings: Partial<RenderSettings> = {
    themeId: prefs.themeId,
    aspectRatio: prefs.aspectRatio as AspectRatio,
    exportFormat: "jpeg",
    includeAttribution: true
  };

  currentRequest.settingsOverride = settings;

  await browser.storage.sync.set({ userPreferences: prefs });
  await renderQuoteCard(true);
}

async function init(): Promise<void> {
  try {
    setState("loading");

    await populateThemeSelector();

    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
    if (!tab?.id) {
      setState("error", "Could not access current tab");
      return;
    }

    activeTabId = tab.id;

    const selectionResp = await browser.tabs.sendMessage(tab.id, {
      type: "REQUEST_SELECTION"
    });

    if (!selectionResp || !selectionResp.text) {
      setState("empty");
      return;
    }

    const storage = await browser.storage.sync.get(["userPreferences"]);
    const prefs = storage.userPreferences || {
      themeId: "scholarly",
      aspectRatio: "portrait"
    };

    const settings: Partial<RenderSettings> = {
      themeId: prefs.themeId as string,
      aspectRatio: prefs.aspectRatio as AspectRatio,
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
  } catch (error) {
    if (isConnectionError(error)) {
      setState("error", "Please reload the page and try again");
    } else {
      console.error("Popup initialization error:", error);
      setState("error", "Failed to initialize popup");
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
