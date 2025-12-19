// Shared types for QuoteCard extension
// These types must be kept in sync with Swift Codable structs

export type AspectRatio = "square" | "portrait" | "landscape";
export type ExportFormat = "png" | "jpeg";

export interface RenderSettings {
  themeId: string;
  aspectRatio: AspectRatio;
  exportFormat: ExportFormat;
  includeAttribution: boolean;
}

export interface RenderRequest {
  id: string;
  text: string;
  html?: string;
  sourceTitle?: string;
  sourceUrl?: string;
  faviconUrl?: string;
  createdAt: number;
  settingsOverride?: Partial<RenderSettings>;
}

export interface RenderResult {
  id: string;
  success: boolean;
  errorMessage?: string;
  dataUrl?: string;
}

export interface SelectionResponse {
  type: "SELECTION_RESPONSE";
  text: string | null;
  html?: string;
  sourceTitle?: string;
  sourceUrl?: string;
  faviconUrl?: string;
}

export interface CopyRequest {
  dataUrl: string;
}

export interface CopyResult {
  success: boolean;
  errorMessage?: string;
}

export interface SaveRequest {
  dataUrl: string;
  sourceTitle?: string;
}

export interface SaveResult {
  success: boolean;
  errorMessage?: string;
  filename?: string;
}

export interface ThemeFont {
  family: string;
  fallback: string;
  weight: number;
}

export interface ThemeBackground {
  type?: "solid" | "gradient" | "image";
  color?: string;
  gradient?: {
    colors: string[];
    direction: "vertical" | "horizontal";
  };
  image?: {
    url: string;
  };
}

export interface ThemeText {
  color: string;
  fontSize: number;
  lineHeight: number;
  glow?: {
    color: string;
    radius: number;
    opacity: number;
  };
}

export interface ThemeFooter {
  enabled: boolean;
  color: string;
  fontSize: number;
  opacity: number;
}

export interface ThemeLayout {
  padding: number;
}

export interface Theme {
  id: string;
  name: string;
  description: string;
  font: ThemeFont;
  background: ThemeBackground;
  text: ThemeText;
  footer: ThemeFooter;
  layout: ThemeLayout;
}

export interface ThemesData {
  version: number;
  themes: Theme[];
}

// Message types for inter-script communication
export type MessageType =
  | "REQUEST_SELECTION"
  | "SELECTION_RESPONSE"
  | "RENDER_REQUEST"
  | "RENDER_REQUEST_RELAY"
  | "COPY_REQUEST"
  | "COPY_REQUEST_RELAY"
  | "SAVE_REQUEST_RELAY"
  | "CONTEXT_MENU_CLICKED";

export interface BaseMessage {
  type: MessageType;
}

export interface RequestSelectionMessage extends BaseMessage {
  type: "REQUEST_SELECTION";
}

export interface RenderRequestMessage extends BaseMessage {
  type: "RENDER_REQUEST";
  payload: RenderRequest;
}

export interface RenderRequestRelayMessage extends BaseMessage {
  type: "RENDER_REQUEST_RELAY";
  payload: RenderRequest;
}

export interface CopyRequestMessage extends BaseMessage {
  type: "COPY_REQUEST";
  payload: CopyRequest;
}

export interface CopyRequestRelayMessage extends BaseMessage {
  type: "COPY_REQUEST_RELAY";
  payload: CopyRequest;
}

export interface SaveRequestRelayMessage extends BaseMessage {
  type: "SAVE_REQUEST_RELAY";
  payload: SaveRequest;
}

export type ExtensionMessage =
  | RequestSelectionMessage
  | RenderRequestMessage
  | RenderRequestRelayMessage
  | CopyRequestMessage
  | CopyRequestRelayMessage
  | SaveRequestRelayMessage;
