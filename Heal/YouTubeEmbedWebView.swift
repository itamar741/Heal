//
//  YouTubeEmbedWebView.swift
//  Heal
//
//  Slice 1–2: thin WKWebView wrapper for official YouTube embed playback.
//  Slice 2 reuses this wrapper for one active video at a time in the pager.
//  Owns creation, inline media config, load/retry, and teardown only.
//

import SwiftUI
import WebKit

enum YouTubeEmbedLoadState: Equatable {
    case loading
    case loaded
    case failed
}

struct YouTubeEmbedWebView: UIViewRepresentable {
    let videoID: String
    @Binding var loadState: YouTubeEmbedLoadState
    var retryToken: Int

    /// HTTPS identity derived from the app Bundle ID for YouTube embed Referer/origin.
    static var appIdentityURL: URL? {
        guard let bundleID = Bundle.main.bundleIdentifier?.lowercased(),
              !bundleID.isEmpty else {
            return nil
        }
        return URL(string: "https://\(bundleID)")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.allowsBackForwardNavigationGestures = false

        context.coordinator.webView = webView
        context.coordinator.loadEmbed(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.lastRetryToken != retryToken {
            context.coordinator.lastRetryToken = retryToken
            context.coordinator.loadEmbed(in: webView)
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.teardown(webView: uiView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: YouTubeEmbedWebView
        weak var webView: WKWebView?
        var lastRetryToken: Int

        init(parent: YouTubeEmbedWebView) {
            self.parent = parent
            self.lastRetryToken = parent.retryToken
        }

        func loadEmbed(in webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.loadState = .loading
            }

            guard let appIdentityURL = YouTubeEmbedWebView.appIdentityURL else {
                DispatchQueue.main.async {
                    self.parent.loadState = .failed
                }
                return
            }

            let encodedID = parent.videoID
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? parent.videoID

            var embedComponents = URLComponents()
            embedComponents.scheme = "https"
            embedComponents.host = "www.youtube.com"
            embedComponents.path = "/embed/\(encodedID)"
            embedComponents.queryItems = [
                URLQueryItem(name: "autoplay", value: "1"),
                URLQueryItem(name: "playsinline", value: "1"),
                URLQueryItem(name: "controls", value: "1"),
                URLQueryItem(name: "rel", value: "0"),
                URLQueryItem(name: "loop", value: "1"),
                URLQueryItem(name: "playlist", value: parent.videoID),
                URLQueryItem(name: "origin", value: appIdentityURL.absoluteString),
            ]

            guard let embedSrc = embedComponents.url?.absoluteString else {
                DispatchQueue.main.async {
                    self.parent.loadState = .failed
                }
                return
            }

            // Official YouTube embed. Identity comes from Bundle ID via baseURL + origin.
            // Requests autoplay; audio may still require a tap.
            // No mute, IFrame API, script bridges, or JS autoplay workarounds.
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
              <style>
                html, body {
                  margin: 0;
                  padding: 0;
                  width: 100%;
                  height: 100%;
                  background: #000;
                  overflow: hidden;
                }
                iframe {
                  position: absolute;
                  top: 0;
                  left: 0;
                  width: 100%;
                  height: 100%;
                  border: 0;
                }
              </style>
            </head>
            <body>
              <iframe
                src="\(embedSrc)"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                referrerpolicy="strict-origin-when-cross-origin"
                allowfullscreen
              ></iframe>
            </body>
            </html>
            """

            webView.loadHTMLString(html, baseURL: appIdentityURL)
        }

        func teardown(webView: WKWebView) {
            webView.stopLoading()
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            webView.loadHTMLString("", baseURL: nil)
            self.webView = nil
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            // Keep playback inside Heal — block app schemes and non-web targets.
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "http" || scheme == "https" || scheme == "about" {
                decisionHandler(.allow)
                return
            }

            decisionHandler(.cancel)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Cancel popups / target=_blank. Do not open Safari/YouTube or
            // replace the embed with a full YouTube page in this WKWebView.
            return nil
        }

        // Navigation-state notes (Slice 1 — no IFrame API):
        // - didFinish means the wrapping WKWebView document/navigation loaded.
        // - It does not prove the YouTube iframe is playable or ready.
        // - WKNavigationDelegate does not detect YouTube player-level errors reliably.
        // - Errors such as 152-4 render inside the iframe and may not surface here.
        // - App identity (baseURL + origin) addresses API client identity / Referer.
        // - Network failures only inside the iframe may not surface here.
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.loadState = .loading
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.loadState = .loaded
            }
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            reportFailure(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            reportFailure(error)
        }

        private func reportFailure(_ error: Error) {
            let nsError = error as NSError
            // Ignore cancellation from intentional stop/reload.
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return
            }
            DispatchQueue.main.async {
                self.parent.loadState = .failed
            }
        }
    }
}
