let elements = null;
export function initUI() {
    elements = {
        loading: document.getElementById("loading"),
        preview: document.getElementById("preview"),
        emptyState: document.getElementById("empty-state"),
        error: document.getElementById("error"),
        cardPreview: document.getElementById("card-preview"),
        errorMessage: document.querySelector("#error .error-message")
    };
    return elements;
}
export function setState(state, errorMessage) {
    if (!elements)
        throw new Error("UI not initialized");
    const { loading, preview, emptyState, error, cardPreview, errorMessage: errorMsgEl } = elements;
    // Reset all states
    loading.classList.add("hidden");
    preview.classList.add("hidden");
    emptyState.classList.add("hidden");
    error.classList.add("hidden");
    switch (state) {
        case "loading":
            loading.classList.remove("hidden");
            break;
        case "cardLoading":
            cardPreview.innerHTML = '<div class="card-spinner"><div class="spinner"></div></div>';
            preview.classList.remove("hidden");
            break;
        case "preview":
            preview.classList.remove("hidden");
            break;
        case "empty":
            emptyState.classList.remove("hidden");
            break;
        case "error":
            error.classList.remove("hidden");
            if (errorMessage) {
                errorMsgEl.textContent = errorMessage;
            }
            break;
    }
}
export function getCardPreview() {
    if (!elements)
        throw new Error("UI not initialized");
    return elements.cardPreview;
}
export async function withButtonState(button, action, labels, onSuccess, successDuration = 2000) {
    const initialText = button.textContent;
    try {
        button.textContent = labels.loading;
        button.disabled = true;
        const result = await action();
        const success = onSuccess ? onSuccess(result) : true;
        if (success) {
            button.textContent = labels.success;
            setTimeout(() => {
                button.textContent = labels.initial;
                button.disabled = false;
            }, successDuration);
        }
        else {
            button.textContent = labels.initial;
            button.disabled = false;
        }
        return result;
    }
    catch {
        button.textContent = initialText || labels.initial;
        button.disabled = false;
        return undefined;
    }
}
