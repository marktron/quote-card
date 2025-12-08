export type UIState = "loading" | "cardLoading" | "preview" | "empty" | "error";

export interface UIElements {
  loading: HTMLElement;
  preview: HTMLElement;
  emptyState: HTMLElement;
  error: HTMLElement;
  cardPreview: HTMLElement;
  errorMessage: Element;
}

let elements: UIElements | null = null;

export function initUI(): UIElements {
  elements = {
    loading: document.getElementById("loading")!,
    preview: document.getElementById("preview")!,
    emptyState: document.getElementById("empty-state")!,
    error: document.getElementById("error")!,
    cardPreview: document.getElementById("card-preview")!,
    errorMessage: document.querySelector("#error .error-message")!
  };
  return elements;
}

export function setState(state: UIState, errorMessage?: string): void {
  if (!elements) throw new Error("UI not initialized");

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

export function getCardPreview(): HTMLElement {
  if (!elements) throw new Error("UI not initialized");
  return elements.cardPreview;
}

interface ButtonStateLabels {
  loading: string;
  success: string;
  initial: string;
}

export async function withButtonState<T>(
  button: HTMLButtonElement,
  action: () => Promise<T>,
  labels: ButtonStateLabels,
  onSuccess?: (result: T) => boolean,
  successDuration = 2000
): Promise<T | undefined> {
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
    } else {
      button.textContent = labels.initial;
      button.disabled = false;
    }

    return result;
  } catch {
    button.textContent = initialText || labels.initial;
    button.disabled = false;
    return undefined;
  }
}
