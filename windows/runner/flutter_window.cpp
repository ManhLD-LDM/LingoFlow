#include "flutter_window.h"

#include <optional>
#include <vector>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / resizing in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  SetupNativeMethodChannel();

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  return true;
}

void FlutterWindow::SetupNativeMethodChannel() {
  native_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "com.lingoflow/native",
      &flutter::StandardMethodCodec::GetInstance());

  native_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();
        HWND hwnd = GetHandle();

        if (method == "setClickThrough") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          bool enable = false;
          if (args) {
            auto it = args->find(flutter::EncodableValue("enable"));
            if (it != args->end() && std::holds_alternative<bool>(it->second)) {
              enable = std::get<bool>(it->second);
            }
          }
          LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
          if (enable) {
            SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_TRANSPARENT | WS_EX_LAYERED);
          } else {
            SetWindowLongPtr(hwnd, GWL_EXSTYLE, (exStyle & ~WS_EX_TRANSPARENT) | WS_EX_LAYERED);
          }
          SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
          result->Success(flutter::EncodableValue(true));
        } else if (method == "setAlwaysOnTop") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          bool enable = true;
          if (args) {
            auto it = args->find(flutter::EncodableValue("enable"));
            if (it != args->end() && std::holds_alternative<bool>(it->second)) {
              enable = std::get<bool>(it->second);
            }
          }
          SetWindowPos(hwnd, enable ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE);
          result->Success(flutter::EncodableValue(true));
        } else if (method == "setWindowOpacity") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          double opacity = 1.0;
          if (args) {
            auto it = args->find(flutter::EncodableValue("opacity"));
            if (it != args->end() && std::holds_alternative<double>(it->second)) {
              opacity = std::get<double>(it->second);
            }
          }
          LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
          SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_LAYERED);
          BYTE alpha = static_cast<BYTE>(opacity * 255.0);
          SetLayeredWindowAttributes(hwnd, 0, alpha, LWA_ALPHA);
          result->Success(flutter::EncodableValue(true));
        } else if (method == "captureScreen") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          int x = 0, y = 0, width = 0, height = 0;
          if (args) {
            auto itX = args->find(flutter::EncodableValue("x"));
            auto itY = args->find(flutter::EncodableValue("y"));
            auto itW = args->find(flutter::EncodableValue("width"));
            auto itH = args->find(flutter::EncodableValue("height"));
            if (itX != args->end() && std::holds_alternative<int32_t>(itX->second)) x = std::get<int32_t>(itX->second);
            if (itY != args->end() && std::holds_alternative<int32_t>(itY->second)) y = std::get<int32_t>(itY->second);
            if (itW != args->end() && std::holds_alternative<int32_t>(itW->second)) width = std::get<int32_t>(itW->second);
            if (itH != args->end() && std::holds_alternative<int32_t>(itH->second)) height = std::get<int32_t>(itH->second);
          }

          HDC hScreenDC = GetDC(nullptr);
          if (width <= 0) width = GetDeviceCaps(hScreenDC, HORZRES);
          if (height <= 0) height = GetDeviceCaps(hScreenDC, VERTRES);

          HDC hMemoryDC = CreateCompatibleDC(hScreenDC);
          HBITMAP hBitmap = CreateCompatibleBitmap(hScreenDC, width, height);
          HBITMAP hOldBitmap = (HBITMAP)SelectObject(hMemoryDC, hBitmap);

          BitBlt(hMemoryDC, 0, 0, width, height, hScreenDC, x, y, SRCCOPY);

          BITMAPINFO bmi = {0};
          bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
          bmi.bmiHeader.biWidth = width;
          bmi.bmiHeader.biHeight = -height; // top-down
          bmi.bmiHeader.biPlanes = 1;
          bmi.bmiHeader.biBitCount = 32;
          bmi.bmiHeader.biCompression = BI_RGB;

          std::vector<uint8_t> pixels(width * height * 4);
          GetDIBits(hMemoryDC, hBitmap, 0, height, pixels.data(), &bmi, DIB_RGB_COLORS);

          SelectObject(hMemoryDC, hOldBitmap);
          DeleteObject(hBitmap);
          DeleteDC(hMemoryDC);
          ReleaseDC(nullptr, hScreenDC);

          flutter::EncodableMap response;
          response[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
          response[flutter::EncodableValue("height")] = flutter::EncodableValue(height);
          response[flutter::EncodableValue("bytes")] = flutter::EncodableValue(pixels);
          result->Success(flutter::EncodableValue(response));
        } else if (method == "recognizeText") {
          // Native OCR bridge response structure
          flutter::EncodableList blocksList;
          std::string fullText = "";

          flutter::EncodableMap response;
          response[flutter::EncodableValue("fullText")] = flutter::EncodableValue(fullText);
          response[flutter::EncodableValue("blocks")] = flutter::EncodableValue(blocksList);
          result->Success(flutter::EncodableValue(response));
        } else {
          result->NotImplemented();
        }
      });
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}
