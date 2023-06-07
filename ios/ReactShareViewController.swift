import RNShareMenu

class ReactShareViewController: ShareViewController, RCTBridgeDelegate, ReactShareViewDelegate {
  func sourceURL(for bridge: RCTBridge!) -> URL! {
    #if DEBUG
      return RCTBundleURLProvider.sharedSettings()?
        .jsBundleURL(forBundleRoot: "index.share")
    #else
      return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
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

    if let backgroundColorConfig =
      Bundle.main.infoDictionary?[REACT_SHARE_VIEW_BACKGROUND_COLOR_KEY] as? [String: Any]
    {
      if let transparent = backgroundColorConfig[COLOR_TRANSPARENT_KEY] as? Bool, transparent {
        rootView.backgroundColor = nil
      } else {
        let red = (backgroundColorConfig[COLOR_RED_KEY] as? NSNumber)?.floatValue ?? 1
        let green = (backgroundColorConfig[COLOR_GREEN_KEY] as? NSNumber)?.floatValue ?? 1
        let blue = (backgroundColorConfig[COLOR_BLUE_KEY] as? NSNumber)?.floatValue ?? 1
        let alpha = (backgroundColorConfig[COLOR_ALPHA_KEY] as? NSNumber)?.floatValue ?? 1

        rootView.backgroundColor = UIColor(
          red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
      }
    }

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
