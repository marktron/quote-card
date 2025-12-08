export var ErrorCode;
(function (ErrorCode) {
    ErrorCode["NATIVE_MESSAGING"] = "NATIVE_MESSAGING";
    ErrorCode["RELAY_FAILED"] = "RELAY_FAILED";
    ErrorCode["NO_SELECTION"] = "NO_SELECTION";
    ErrorCode["RENDER_FAILED"] = "RENDER_FAILED";
    ErrorCode["COPY_FAILED"] = "COPY_FAILED";
    ErrorCode["SAVE_FAILED"] = "SAVE_FAILED";
    ErrorCode["TAB_ACCESS"] = "TAB_ACCESS";
    ErrorCode["CONNECTION"] = "CONNECTION";
})(ErrorCode || (ErrorCode = {}));
export function createError(code, message, originalError) {
    return { code, message, originalError };
}
export function getUserMessage(error) {
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
export function isConnectionError(error) {
    if (!(error instanceof Error))
        return false;
    const message = error.message;
    return (message.includes("Could not establish connection") ||
        message.includes("Receiving end does not exist"));
}
