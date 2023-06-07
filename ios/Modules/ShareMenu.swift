@objc(ShareMenu)
class ShareMenu: RCTEventEmitter {

    static let shared = ShareMenu()
    var sharedData: [[String:String]?]?
    static var initialShare: (UIApplication, URL, [UIApplication.OpenURLOptionsKey : Any])?
    var hasListeners = false
    var _targetUrlScheme: String?
    
    public override init() {
        super.init()
        if let (app, url, options) = ShareMenu.initialShare {
            share(application: app, openUrl: url, options: options)
        }
    }
    
    override static public func requiresMainQueueSetup() -> Bool {
        return false
    }

    open override func supportedEvents() -> [String]! {
        return [NEW_SHARE_EVENT]
    }

    open override func startObserving() {
        hasListeners = true
    }

    open override func stopObserving() {
        hasListeners = false
    }

    public static func messageShare(
        application app: UIApplication,
        openUrl url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any]
    ) {
        ShareMenu.shared.share(application: app, openUrl: url, options: options)
    }
    
    func share(
        application app: UIApplication,
        openUrl url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any]) {
        
        if _targetUrlScheme == nil {
            guard let expectedUrlScheme = fetchTargetUrlScheme() else {
                print("Error \(NO_URL_SCHEMES_ERROR_MESSAGE)")
                return
            }
            _targetUrlScheme = expectedUrlScheme
        }

        guard let scheme = url.scheme, scheme == _targetUrlScheme else { return }
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        guard let userDefaults = UserDefaults(suiteName: "group.\(bundleId)") else {
            print("Error: \(NO_APP_GROUP_ERROR)")
            return
        }

        let extraData = userDefaults.object(forKey: USER_DEFAULTS_EXTRA_DATA_KEY) as? [String:Any]

        if let data = userDefaults.object(forKey: USER_DEFAULTS_KEY) as? [[String:String]] {
            sharedData = data
            dispatchEvent(with: data, and: extraData)
            userDefaults.removeObject(forKey: USER_DEFAULTS_KEY)
        }
    }

    func fetchTargetUrlScheme() -> String? {
        guard let bundleUrlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [NSDictionary] else {
            print("Error: \(NO_URL_TYPES_ERROR_MESSAGE)")
            return nil
        }
        guard let bundleUrlSchemes = bundleUrlTypes.first?.value(forKey: "CFBundleURLSchemes") as? [String] else {
            print("Error: \(NO_URL_SCHEMES_ERROR_MESSAGE)")
            return nil
        }
        guard let expectedUrlScheme = bundleUrlSchemes.first else {
            print("Error \(NO_URL_SCHEMES_ERROR_MESSAGE)")
            return nil
        }

        return expectedUrlScheme
    }

    @objc(getSharedText:)
    func getSharedText(callback: RCTResponseSenderBlock) {
        var data = [DATA_KEY: sharedData] as [String: Any]

        if let bundleId = Bundle.main.bundleIdentifier, let userDefaults = UserDefaults(suiteName: "group.\(bundleId)") {
            data[EXTRA_DATA_KEY] = userDefaults.object(forKey: USER_DEFAULTS_EXTRA_DATA_KEY) as? [String: Any]
        } else {
            print("Error: \(NO_APP_GROUP_ERROR)")
        }

        callback([data as Any])
        sharedData = []
    }
    
    func dispatchEvent(with data: [[String:String]], and extraData: [String:Any]?) {
        guard hasListeners else { return }

        DispatchQueue.main.async { [weak self] in
            var finalData = [DATA_KEY: data] as [String: Any]
            if let extraData = extraData {
                finalData[EXTRA_DATA_KEY] = extraData
            }
            
            self?.sendEvent(withName: NEW_SHARE_EVENT, body: finalData)
        }
    }
}
