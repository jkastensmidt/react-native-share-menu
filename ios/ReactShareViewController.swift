import RNShareMenu

class ReactShareViewController: ShareViewController, RCTBridgeDelegate, ReactShareViewDelegate {
  func sourceURL(for bridge: RCTBridge!) -> URL! {
    #if DEBUG
      guard
        let jsBundleURL = RCTBundleURLProvider.sharedSettings()?.jsBundleURL(
          forBundleRoot: "index.share")
      else {
        fatalError("Cannot find index.share.js")
      }
      return jsBundleURL
    #else
      guard let jsBundleURL = Bundle.main.url(forResource: "main", withExtension: "jsbundle") else {
        fatalError("Cannot find main.jsbundle")
      }
      return jsBundleURL
    #endif
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let bridge: RCTBridge! = RCTBridge(delegate: self, launchOptions: nil)
    let rootView = RCTRootView(
      bridge: bridge,
      moduleName: "ShareMenuModuleComponent",
      initialProperties: nil
    )

    // Set a default color
    rootView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

    self.view = rootView

    ShareMenuReactView.attachViewDelegate(self)
  }

  override func viewDidDisappear(_ animated: Bool) {
    cancel()
    ShareMenuReactView.detachViewDelegate()
  }

  func loadExtensionContext() -> NSExtensionContext {
    guard let context = extensionContext else {
      fatalError("Extension context should not be nil")
    }
    return context
  }

  func openApp() {
    self.openHostApp()
  }

  func continueInApp(with items: [NSExtensionItem], and extraData: [String: Any]?) {
    handlePost(items, extraData: extraData)
  }
}
