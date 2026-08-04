import Foundation
import Security
import CoreLocation
import UIKit

enum KislapAPIError: Error, LocalizedError, Equatable {
    case unavailable
    case invalidResponse
    case server(status: Int, code: String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "The Kislap learning service is not configured."
        case .invalidResponse:
            return "The learning service returned an invalid response."
        case let .server(_, code):
            return code.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

struct KislapRegistrationProfile {
    let displayName: String
    let age: Int
    let gender: String
    let interests: [String]
}

struct KislapLearningSkill: Decodable {
    let slug: String
    let name: String
    let role: String
    let level: String
}

struct KislapLearningPhoto: Decodable {
    let id: String?
    let url: String?
    let thumbUrl: String?
    let order: Int?
    let isMain: Bool?
}

struct KislapLearningPartner: Decodable {
    let userId: String
    let displayName: String
    let age: Int
    let bio: String?
    let interests: [String]
    let distanceLabel: String
    let city: String?
    let verificationStatus: String
    let activityStatus: String
    let skills: [KislapLearningSkill]
    let photos: [KislapLearningPhoto]
    let isDemo: Bool?
}

struct KislapLocationVisibility: Decodable {
    let visible: Bool
    let precision: String
    let expiresAt: String?
}

struct KislapProfileSkill: Decodable {
    struct Skill: Decodable {
        let slug: String
        let name: String
    }

    let role: String
    let level: String
    let skill: Skill
}

struct KislapProfile: Decodable {
    let id: String
    let email: String
    let displayName: String
    let age: Int
    let gender: String
    let bio: String?
    let interests: [String]
    let learningGoal: String?
    let spokenLanguages: [String]
    let availability: String?
    let occupation: String?
    let verificationStatus: String
    let isVisible: Bool
    let datingEnabled: Bool
    let photos: [KislapLearningPhoto]
    let skills: [KislapProfileSkill]
}

struct KislapConnectionPerson: Decodable {
    let id: String
    let displayName: String
    let photos: [KislapLearningPhoto]
}

struct KislapConnection: Decodable {
    let id: String
    let purpose: String
    let otherUser: KislapConnectionPerson
}

struct KislapConnectionRequest: Decodable {
    let id: String
    let purpose: String
    let message: String?
    let sender: KislapConnectionPerson
}

struct KislapConnections: Decodable {
    let connections: [KislapConnection]
    let requests: [KislapConnectionRequest]
}

struct KislapConnectionMessage: Decodable {
    let id: String
    let body: String
    let createdAt: String
    let isMine: Bool
}

final class KislapAPIClient {
    static let shared = KislapAPIClient()

    private struct ErrorEnvelope: Decodable {
        let error: String?
    }

    private struct TokenPair: Decodable {
        let accessToken: String
        let refreshToken: String
    }

    private struct RequestCodeResponse: Decodable {
        let expiresInSeconds: Int
        let devCode: String?
    }

    private struct VerifyResponse: Decodable {
        let tokens: TokenPair
    }

    private struct RefreshResponse: Decodable {
        let tokens: TokenPair
    }

    private struct PartnersResponse: Decodable {
        let users: [KislapLearningPartner]
    }

    private struct ProfileResponse: Decodable {
        let profile: KislapProfile
    }

    private struct PhotoResponse: Decodable {
        let photo: KislapLearningPhoto
    }

    private struct ConnectionMessagesResponse: Decodable {
        let messages: [KislapConnectionMessage]
    }

    private struct SendConnectionMessageResponse: Decodable {
        let message: KislapConnectionMessage
    }

    private struct UpdateLocationResponse: Decodable {
        struct Visibility: Decodable {
            let expiresAt: String
        }
        let visibility: Visibility
    }

    private let session: URLSession
    private let baseURL: URL?
    private let keychainService: String
    private let stateQueue = DispatchQueue(label: "ph.kislap.api-session")
    private var accessToken: String?
    private var refreshInFlight = false
    private var refreshWaiters: [(Result<String, Error>) -> Void] = []
    private let imageCache = NSCache<NSURL, UIImage>()

    private init() {
        self.session = URLSession(configuration: .ephemeral)
        self.keychainService = (Bundle.main.bundleIdentifier ?? "ph.kislap") + ".learning-session"

        if let configured = Bundle.main.object(forInfoDictionaryKey: "KislapAPIBaseURL") as? String,
           let url = URL(string: configured), !configured.isEmpty {
            self.baseURL = url
        } else if Bundle.main.bundleIdentifier?.hasSuffix(".dev") == true {
#if targetEnvironment(simulator)
            // The simulator shares the Mac development loopback service.
            self.baseURL = URL(string: "http://127.0.0.1:3000")
#else
            // On a physical iPhone, loopback points to the phone itself.
            self.baseURL = URL(string: "https://api.kislap.org")
#endif
        } else {
            self.baseURL = URL(string: "https://api.kislap.org")
        }
    }

    var hasSession: Bool {
        return self.readSecret(account: "refresh-token") != nil
    }

    func requestLoginCode(email: String, completion: @escaping (Result<String?, Error>) -> Void) {
        self.request(path: "/api/v1/auth/request-code", method: "POST", body: ["email": email], accessToken: nil) { (result: Result<RequestCodeResponse, Error>) in
            completion(result.map(\.devCode))
        }
    }

    func verifyLoginCode(
        email: String,
        code: String,
        profile: KislapRegistrationProfile?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var body: [String: Any] = ["email": email, "code": code]
        if let profile {
            body["profile"] = [
                "displayName": profile.displayName,
                "age": profile.age,
                "gender": profile.gender,
                "interests": profile.interests,
                "acceptsPolicies": true,
            ]
        }
        self.request(path: "/api/v1/auth/verify-code", method: "POST", body: body, accessToken: nil) { (result: Result<VerifyResponse, Error>) in
            switch result {
            case let .success(response):
                self.save(tokens: response.tokens)
                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func updateLocation(_ location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let body: [String: Any] = [
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude,
        ]
        self.authorizedRequest(path: "/api/v1/location", method: "POST", body: body) { (result: Result<UpdateLocationResponse, Error>) in
            completion(result.map { $0.visibility.expiresAt })
        }
    }

    func locationStatus(completion: @escaping (Result<KislapLocationVisibility, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/location/status", method: "GET", body: nil, completion: completion)
    }

    func disableLocation(completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/location", method: "DELETE", body: nil) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func learningPartners(skill: String, completion: @escaping (Result<[KislapLearningPartner], Error>) -> Void) {
        let encodedSkill = skill.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? skill
        self.authorizedRequest(path: "/api/v1/learning-partners?skill=\(encodedSkill)&radiusKm=10&limit=20", method: "GET", body: nil) { (result: Result<PartnersResponse, Error>) in
            completion(result.map(\.users))
        }
    }

    func profile(completion: @escaping (Result<KislapProfile, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/profile", method: "GET", body: nil) { (result: Result<ProfileResponse, Error>) in
            completion(result.map(\.profile))
        }
    }

    func updateProfile(
        displayName: String,
        bio: String,
        learningGoal: String,
        spokenLanguages: [String],
        availability: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        self.authorizedRequest(path: "/api/v1/profile", method: "PATCH", body: [
            "displayName": displayName,
            "bio": bio,
            "learningGoal": learningGoal,
            "spokenLanguages": spokenLanguages,
            "availability": availability,
        ]) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func updateDating(enabled: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/profile", method: "PATCH", body: [
            "datingEnabled": enabled,
            "relationshipGoal": enabled ? "BOTH" : "FRIENDS",
        ]) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func updateSkills(
        learning: [(slug: String, level: String)],
        teaching: [(slug: String, level: String)],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let body: [String: Any] = [
            "learning": learning.map { ["slug": $0.slug, "level": $0.level] },
            "teaching": teaching.map { ["slug": $0.slug, "level": $0.level] },
        ]
        self.authorizedRequest(path: "/api/v1/profile/skills", method: "PUT", body: body) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func uploadProfilePhoto(
        data: Data,
        fileName: String = "learning-profile.jpg",
        mimeType: String = "image/jpeg",
        completion: @escaping (Result<KislapLearningPhoto, Error>) -> Void
    ) {
        self.withAccessToken { result in
            switch result {
            case let .success(token):
                self.performPhotoUpload(data: data, fileName: fileName, mimeType: mimeType, accessToken: token) { result in
                    if case let .failure(KislapAPIError.server(status, _)) = result, status == 401 {
                        self.stateQueue.sync { self.accessToken = nil }
                        self.withAccessToken { refreshResult in
                            switch refreshResult {
                            case let .success(refreshedToken):
                                self.performPhotoUpload(data: data, fileName: fileName, mimeType: mimeType, accessToken: refreshedToken, completion: completion)
                            case let .failure(error):
                                completion(.failure(error))
                            }
                        }
                    } else {
                        completion(result)
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func deleteProfilePhoto(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/profile/photos/\(id)", method: "DELETE", body: nil) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func setMainProfilePhoto(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/profile/photos/\(id)/main", method: "PUT", body: nil) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func deleteLearningAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/account", method: "DELETE", body: nil) { (result: Result<EmptyResponse, Error>) in
            if case .success = result {
                self.signOut()
            }
            completion(result.map { _ in () })
        }
    }

    func connections(completion: @escaping (Result<KislapConnections, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/connections", method: "GET", body: nil, completion: completion)
    }

    func respondToConnectionRequest(id: String, accept: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/connections/requests/\(id)/respond", method: "POST", body: ["accept": accept]) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func removeConnection(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/connections/\(id)", method: "DELETE", body: nil) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func connectionMessages(id: String, completion: @escaping (Result<[KislapConnectionMessage], Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/connections/\(id)/messages", method: "GET", body: nil) { (result: Result<ConnectionMessagesResponse, Error>) in
            completion(result.map(\.messages))
        }
    }

    func sendConnectionMessage(id: String, body: String, completion: @escaping (Result<KislapConnectionMessage, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/connections/\(id)/messages", method: "POST", body: ["body": body]) { (result: Result<SendConnectionMessageResponse, Error>) in
            completion(result.map(\.message))
        }
    }

    func requestStudyConnection(userId: String, skill: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let topic = skill.replacingOccurrences(of: "-", with: " ")
        self.authorizedRequest(path: "/api/v1/connections/requests", method: "POST", body: [
            "targetUserId": userId,
            "purpose": "STUDY_PARTNER",
            "message": "Would you like to practise \(topic) together?",
        ]) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func loadProfileImage(path: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = self.assetURL(path: path) else {
            completion(nil)
            return
        }
        if let cached = self.imageCache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }
        self.session.dataTask(with: url) { [weak self] data, response, _ in
            guard let self,
                  let http = response as? HTTPURLResponse,
                  (200 ..< 300).contains(http.statusCode),
                  let data,
                  data.count <= 5 * 1024 * 1024,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            self.imageCache.setObject(image, forKey: url as NSURL)
            completion(image)
        }.resume()
    }

    func block(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/block/\(userId)", method: "POST", body: nil) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func report(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.report(userId: userId, reason: "OTHER", description: "Reported from Nearby Learning", completion: completion)
    }

    func report(userId: String, reason: String, description: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.authorizedRequest(path: "/api/v1/report", method: "POST", body: [
            "reportedUserId": userId,
            "reason": reason,
            "description": description,
        ]) { (result: Result<EmptyResponse, Error>) in
            completion(result.map { _ in () })
        }
    }

    func signOut() {
        self.stateQueue.sync {
            self.accessToken = nil
        }
        self.deleteSecret(account: "refresh-token")
    }

    /** Revoke the refresh token on the server, then remove the device copy. */
    func disconnect(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let refreshToken = self.readSecret(account: "refresh-token") else {
            self.signOut()
            completion(.success(()))
            return
        }
        self.request(path: "/api/v1/auth/logout", method: "POST", body: ["refreshToken": refreshToken], accessToken: nil) { (result: Result<EmptyResponse, Error>) in
            self.signOut()
            completion(result.map { _ in () })
        }
    }

    private struct EmptyResponse: Decodable {}

    private func assetURL(path: String) -> URL? {
        if let absolute = URL(string: path), let scheme = absolute.scheme {
            if scheme == "https" {
                return absolute
            }
            if scheme == "http", self.baseURL?.scheme == "http", absolute.host == self.baseURL?.host {
                return absolute
            }
            return nil
        }
        return URL(string: path, relativeTo: self.baseURL)?.absoluteURL
    }

    private func authorizedRequest<T: Decodable>(
        path: String,
        method: String,
        body: [String: Any]?,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        self.withAccessToken { result in
            switch result {
            case let .success(token):
                self.request(path: path, method: method, body: body, accessToken: token) { (requestResult: Result<T, Error>) in
                    if case let .failure(KislapAPIError.server(status, _)) = requestResult, status == 401 {
                        self.stateQueue.sync { self.accessToken = nil }
                        self.withAccessToken { refreshResult in
                            switch refreshResult {
                            case let .success(refreshedToken):
                                self.request(path: path, method: method, body: body, accessToken: refreshedToken, completion: completion)
                            case let .failure(error):
                                completion(.failure(error))
                            }
                        }
                    } else {
                        completion(requestResult)
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func performPhotoUpload(
        data: Data,
        fileName: String,
        mimeType: String,
        accessToken: String,
        completion: @escaping (Result<KislapLearningPhoto, Error>) -> Void
    ) {
        guard let baseURL = self.baseURL, let url = URL(string: "/api/v1/profile/photos", relativeTo: baseURL) else {
            completion(.failure(KislapAPIError.unavailable))
            return
        }

        let boundary = "KislapBoundary-\(UUID().uuidString)"
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        self.session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse, let data else {
                completion(.failure(KislapAPIError.invalidResponse))
                return
            }
            guard (200 ..< 300).contains(http.statusCode) else {
                let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data)
                completion(.failure(KislapAPIError.server(status: http.statusCode, code: envelope?.error ?? "upload_failed")))
                return
            }
            do {
                completion(.success(try JSONDecoder().decode(PhotoResponse.self, from: data).photo))
            } catch {
                completion(.failure(KislapAPIError.invalidResponse))
            }
        }.resume()
    }

    private func withAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        self.stateQueue.async {
            if let token = self.accessToken {
                completion(.success(token))
                return
            }

            self.refreshWaiters.append(completion)
            if self.refreshInFlight {
                return
            }

            guard let refreshToken = self.readSecret(account: "refresh-token") else {
                self.finishRefresh(.failure(KislapAPIError.server(status: 401, code: "learning_sign_in_required")))
                return
            }

            self.refreshInFlight = true
            self.request(
                path: "/api/v1/auth/refresh",
                method: "POST",
                body: ["refreshToken": refreshToken],
                accessToken: nil
            ) { (result: Result<RefreshResponse, Error>) in
                self.stateQueue.async {
                    switch result {
                    case let .success(response):
                        self.accessToken = response.tokens.accessToken
                        self.writeSecret(response.tokens.refreshToken, account: "refresh-token")
                        self.finishRefresh(.success(response.tokens.accessToken))
                    case let .failure(error):
                        self.accessToken = nil
                        // A temporary network or server failure must not sign the
                        // user out. Remove the device credential only when the
                        // refresh token itself was rejected.
                        if case let KislapAPIError.server(status, _) = error, status == 401 {
                            self.deleteSecret(account: "refresh-token")
                        }
                        self.finishRefresh(.failure(error))
                    }
                }
            }
        }
    }

    /** Must be called on stateQueue. */
    private func finishRefresh(_ result: Result<String, Error>) {
        let waiters = self.refreshWaiters
        self.refreshWaiters.removeAll()
        self.refreshInFlight = false
        for waiter in waiters {
            waiter(result)
        }
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: [String: Any]?,
        accessToken: String?,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let baseURL = self.baseURL, let url = URL(string: path, relativeTo: baseURL) else {
            completion(.failure(KislapAPIError.unavailable))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 12.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion(.failure(error))
                return
            }
        }

        self.session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse, let data else {
                completion(.failure(KislapAPIError.invalidResponse))
                return
            }
            guard (200 ..< 300).contains(http.statusCode) else {
                let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data)
                completion(.failure(KislapAPIError.server(status: http.statusCode, code: envelope?.error ?? "request_failed")))
                return
            }
            if T.self == EmptyResponse.self && data.isEmpty {
                completion(.success(EmptyResponse() as! T))
                return
            }
            do {
                completion(.success(try JSONDecoder().decode(T.self, from: data)))
            } catch {
                completion(.failure(KislapAPIError.invalidResponse))
            }
        }.resume()
    }

    private func save(tokens: TokenPair) {
        self.stateQueue.sync {
            self.accessToken = tokens.accessToken
        }
        self.writeSecret(tokens.refreshToken, account: "refresh-token")
    }

    private func readSecret(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func writeSecret(_ value: String, account: String) {
        self.deleteSecret(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.keychainService,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: Data(value.utf8),
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func deleteSecret(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
