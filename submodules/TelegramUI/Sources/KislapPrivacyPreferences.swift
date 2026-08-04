import Foundation

extension Notification.Name {
    static let kislapPrivacyPreferencesDidChange = Notification.Name("ph.kislap.privacy-preferences.changed")
}

enum KislapStealthDuration: Int {
    case oneHour
    case eightHours
    case always
}

enum KislapPrivacyPreferences {
    private enum Key {
        static let peekModeEnabled = "ph.kislap.privacy.peek-mode-enabled"
        static let stealthModeEnabled = "ph.kislap.privacy.stealth-mode-enabled"
        static let stealthModeExpiresAt = "ph.kislap.privacy.stealth-mode-expires-at"
    }

    static var isPeekModeEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.peekModeEnabled)
        }
        set {
            guard newValue != self.isPeekModeEnabled else {
                return
            }
            UserDefaults.standard.set(newValue, forKey: Key.peekModeEnabled)
            self.notifyChange()
        }
    }

    static var isStealthModeEnabled: Bool {
        get {
            guard UserDefaults.standard.bool(forKey: Key.stealthModeEnabled) else {
                return false
            }
            let expiresAt = UserDefaults.standard.double(forKey: Key.stealthModeExpiresAt)
            if expiresAt > 0.0 && expiresAt <= Date().timeIntervalSince1970 {
                UserDefaults.standard.set(false, forKey: Key.stealthModeEnabled)
                UserDefaults.standard.removeObject(forKey: Key.stealthModeExpiresAt)
                DispatchQueue.main.async {
                    self.notifyChange()
                }
                return false
            }
            return true
        }
        set {
            guard newValue != self.isStealthModeEnabled else {
                return
            }
            UserDefaults.standard.set(newValue, forKey: Key.stealthModeEnabled)
            if newValue {
                UserDefaults.standard.removeObject(forKey: Key.stealthModeExpiresAt)
            } else {
                UserDefaults.standard.removeObject(forKey: Key.stealthModeExpiresAt)
            }
            self.notifyChange()
        }
    }

    static var stealthDuration: KislapStealthDuration {
        let expiresAt = UserDefaults.standard.double(forKey: Key.stealthModeExpiresAt)
        guard expiresAt > 0.0 else {
            return .always
        }
        let remaining = expiresAt - Date().timeIntervalSince1970
        return remaining <= 60.0 * 60.0 + 5.0 ? .oneHour : .eightHours
    }

    static var stealthExpiresAt: Date? {
        guard self.isStealthModeEnabled else {
            return nil
        }
        let value = UserDefaults.standard.double(forKey: Key.stealthModeExpiresAt)
        return value > 0.0 ? Date(timeIntervalSince1970: value) : nil
    }

    static func enableStealth(for duration: KislapStealthDuration) {
        UserDefaults.standard.set(true, forKey: Key.stealthModeEnabled)
        switch duration {
        case .oneHour:
            UserDefaults.standard.set(Date().timeIntervalSince1970 + 60.0 * 60.0, forKey: Key.stealthModeExpiresAt)
        case .eightHours:
            UserDefaults.standard.set(Date().timeIntervalSince1970 + 8.0 * 60.0 * 60.0, forKey: Key.stealthModeExpiresAt)
        case .always:
            UserDefaults.standard.removeObject(forKey: Key.stealthModeExpiresAt)
        }
        self.notifyChange()
    }

    static var suppressesAutomaticReadAdvancement: Bool {
        return self.isPeekModeEnabled
    }

    static var suppressesPeerActivityBroadcasts: Bool {
        return self.isStealthModeEnabled
    }

    private static func notifyChange() {
        NotificationCenter.default.post(name: .kislapPrivacyPreferencesDidChange, object: nil)
    }
}
