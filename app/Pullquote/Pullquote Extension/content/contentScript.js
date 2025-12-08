"use strict";
const ERROR_CODE_RELAY_FAILED = "RELAY_FAILED";
/**
 * Get the currently selected text and HTML from the page
 */
function getSelectionContent() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) {
        return { text: null, html: null };
    }
    const text = selection.toString().trim();
    if (!text) {
        return { text: null, html: null };
    }
    try {
        // Get HTML content while preserving structure
        const range = selection.getRangeAt(0);
        const container = document.createElement("div");
        container.appendChild(range.cloneContents());
        // Clean up the HTML
        const html = cleanHTML(container);
        return { text, html };
    }
    catch {
        return { text, html: null };
    }
}
/**
 * Clean and simplify HTML, preserving only formatting we care about
 */
function cleanHTML(container) {
    // Remove script and style elements
    container.querySelectorAll("script, style").forEach(el => el.remove());
    // Remove footnote links (e.g., Wikipedia reference links)
    container.querySelectorAll("sup.reference").forEach(el => el.remove());
    // Remove Wikipedia edit section links
    container.querySelectorAll("span.mw-editsection").forEach(el => el.remove());
    // Convert headlines (H1-H6) to bold before processing
    container.querySelectorAll("h1, h2, h3, h4, h5, h6").forEach(headline => {
        const strong = document.createElement("strong");
        while (headline.firstChild) {
            strong.appendChild(headline.firstChild);
        }
        headline.parentNode?.replaceChild(strong, headline);
    });
    // Process all nodes to preserve only semantic formatting
    processNode(container);
    return container.innerHTML.trim();
}
/**
 * Process a node to keep only the formatting we want
 */
function processNode(node) {
    if (node.nodeType === Node.ELEMENT_NODE) {
        const element = node;
        // Keep these semantic tags
        const keepTags = ["em", "i", "strong", "b", "p", "br", "ul", "ol", "li", "blockquote"];
        const tagName = element.tagName.toLowerCase();
        // Process children first (before we potentially remove the element)
        const children = Array.from(element.childNodes);
        children.forEach(child => processNode(child));
        if (!keepTags.includes(tagName)) {
            // Replace with plain text or unwrap children
            if (tagName === "div" || tagName === "span") {
                // Unwrap div/span but keep their content
                const parent = element.parentNode;
                if (parent) {
                    while (element.firstChild) {
                        parent.insertBefore(element.firstChild, element);
                    }
                    parent.removeChild(element);
                }
                return;
            }
            else {
                // For other tags, replace with their text content
                const textNode = document.createTextNode(element.textContent || "");
                element.parentNode?.replaceChild(textNode, element);
                return;
            }
        }
        // Normalize bold/italic tags
        if (tagName === "b") {
            const strong = document.createElement("strong");
            while (element.firstChild) {
                strong.appendChild(element.firstChild);
            }
            element.parentNode?.replaceChild(strong, element);
            return;
        }
        if (tagName === "i") {
            const em = document.createElement("em");
            while (element.firstChild) {
                em.appendChild(element.firstChild);
            }
            element.parentNode?.replaceChild(em, element);
            return;
        }
        // Remove all attributes (class, id, style, etc.)
        while (element.attributes.length > 0) {
            element.removeAttribute(element.attributes[0].name);
        }
    }
}
/**
 * Get the page's favicon URL
 */
function getFaviconUrl() {
    // Try multiple methods to find favicon
    // 1. Look for rel="icon" or rel="shortcut icon"
    const iconLink = document.querySelector('link[rel="icon"], link[rel="shortcut icon"]');
    if (iconLink?.href) {
        return iconLink.href;
    }
    // 2. Look for apple-touch-icon
    const appleIcon = document.querySelector('link[rel="apple-touch-icon"]');
    if (appleIcon?.href) {
        return appleIcon.href;
    }
    // 3. Default to /favicon.ico
    const origin = window.location.origin;
    return `${origin}/favicon.ico`;
}
/**
 * Download favicon and convert to data URL
 */
async function getFaviconDataUrl() {
    const faviconUrl = getFaviconUrl();
    if (!faviconUrl) {
        return undefined;
    }
    try {
        const response = await fetch(faviconUrl);
        if (!response.ok) {
            return undefined;
        }
        const blob = await response.blob();
        return new Promise(resolve => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(reader.result);
            reader.onerror = () => resolve(undefined);
            reader.readAsDataURL(blob);
        });
    }
    catch {
        return undefined;
    }
}
/**
 * Get metadata about the current page
 */
async function getMetadata() {
    const title = document.title || undefined;
    const url = window.location.href || undefined;
    const faviconUrl = await getFaviconDataUrl(); // Now returns data URL instead of URL
    // Try to extract author from meta tags
    const authorMeta = document.querySelector('meta[name="author"]');
    const author = authorMeta?.getAttribute("content") || undefined;
    return { title, url, author, faviconUrl };
}
/**
 * Listen for messages from popup and background script
 */
browser.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
    if (msg.type === "REQUEST_SELECTION") {
        void (async () => {
            const { text, html } = getSelectionContent();
            const meta = await getMetadata();
            const response = {
                type: "SELECTION_RESPONSE",
                text,
                html: html ?? undefined,
                sourceTitle: meta.title,
                sourceUrl: meta.url,
                faviconUrl: meta.faviconUrl
            };
            sendResponse(response);
        })();
        return true;
    }
    if (msg.type === "RENDER_REQUEST_RELAY") {
        browser.runtime
            .sendMessage({
            type: "RENDER_REQUEST",
            payload: msg.payload
        })
            .then((response) => {
            sendResponse(response);
        })
            .catch((error) => {
            console.error(`[${ERROR_CODE_RELAY_FAILED}]`, error.message);
            sendResponse({
                success: false,
                errorMessage: "Failed to communicate with extension background"
            });
        });
        return true;
    }
    if (msg.type === "SAVE_REQUEST_RELAY") {
        const dataUrl = msg.payload?.dataUrl;
        if (!dataUrl) {
            sendResponse({ success: false, errorMessage: "Missing dataUrl" });
            return true;
        }
        const now = new Date();
        const timestamp = now.toISOString().replace(/[:.]/g, "-").slice(0, 19);
        const isJpeg = dataUrl.startsWith("data:image/jpeg");
        const extension = isJpeg ? "jpg" : "png";
        let filename = "pullquote";
        const sourceTitle = msg.payload?.sourceTitle;
        if (sourceTitle) {
            const attribution = sourceTitle
                .replace(/[^a-zA-Z0-9\s-]/g, "")
                .replace(/\s+/g, "-")
                .toLowerCase()
                .slice(0, 50);
            if (attribution) {
                filename = `pullquote-${attribution}-${timestamp}.${extension}`;
            }
            else {
                filename = `pullquote-${timestamp}.${extension}`;
            }
        }
        else {
            filename = `pullquote-${timestamp}.${extension}`;
        }
        const link = document.createElement("a");
        link.href = dataUrl;
        link.download = filename;
        link.style.display = "none";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        sendResponse({ success: true, filename });
        return true;
    }
    if (msg.type === "COPY_REQUEST_RELAY") {
        browser.runtime
            .sendMessage({
            type: "COPY_REQUEST",
            payload: msg.payload
        })
            .then((response) => {
            sendResponse(response);
        })
            .catch((error) => {
            console.error(`[${ERROR_CODE_RELAY_FAILED}]`, error.message);
            sendResponse({
                success: false,
                errorMessage: "Failed to communicate with extension background"
            });
        });
        return true;
    }
    return false;
});
