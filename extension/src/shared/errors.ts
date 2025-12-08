export enum ErrorCode {
  NATIVE_MESSAGING = "NATIVE_MESSAGING",
  RELAY_FAILED = "RELAY_FAILED",
  NO_SELECTION = "NO_SELECTION",
  RENDER_FAILED = "RENDER_FAILED",
  COPY_FAILED = "COPY_FAILED",
  SAVE_FAILED = "SAVE_FAILED",
  TAB_ACCESS = "TAB_ACCESS",
  CONNECTION = "CONNECTION"
}

export interface AppError {
  code: ErrorCode;
  message: string;
  originalError?: Error;
}

export function createError(code: ErrorCode, message: string, originalError?: Error): AppError {
  return { code, message, originalError };
}

export function getUserMessage(error: AppError): string {
  switch (error.code) {
    case ErrorCode.CONNECTION:
      return "Please reload the page and try again";
    case ErrorCode.TAB_ACCESS:
      return "Could not access current tab";
    case ErrorCode.NO_SELECTION:
      return "Please select some text first";
    case ErrorCode.NATIVE_MESSAGING:
      return `Extension error: ${error.message}`;
    case ErrorCode.RELAY_FAILED:
      return "Failed to communicate with extension";
    case ErrorCode.RENDER_FAILED:
      return error.message || "Failed to render quote card";
    case ErrorCode.COPY_FAILED:
      return error.message || "Failed to copy to clipboard";
    case ErrorCode.SAVE_FAILED:
      return error.message || "Failed to save image";
    default:
      return error.message || "An unexpected error occurred";
  }
}

export function isConnectionError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const message = error.message;
  return (
    message.includes("Could not establish connection") ||
    message.includes("Receiving end does not exist")
  );
}
