import UIKit

public final class Login {
    public enum State {
        /// User is signed out, has not started the sign in flow yet.
        case signedOut
        /// Signed out. Begun the sign in flow, requesting an auth code from the server.
        case requestingAuthCode
        /// Signed out. Error requesting auth code from server.
        case requestingAuthCodeFailed(Error)
        /// Signed out. Server returned an auth code that the user must now enter in their web browser on another device to sign in on this device.
        case receivedAuthCode(AuthCode)
        /// User is signed in.
        case signedIn(AuthToken)
    }

    public private(set) var state: State {
        didSet {
            authenticationToken = state.authToken
            screen.state = state
            if (state != oldValue) {
                stateDidChange?(state)
            }
        }
    }
    /// Called by the view controller when the signed in/signed out state changes.
    public var stateDidChange: ((State) -> ())?
    public let screen: LoginViewController
    private let webservice: Webservice
    // TODO: Move to Environment?
    private let keychainToken: KeychainItem

    public init(webservice: Webservice) {
        // TODO: Verify that this is the key we want to use.
        // TODO: Investigate app groups/shared keychains to prepare for keychain sharing with a future iOS app.
        keychainToken = KeychainItem(account: "io.objc.videos.token")

        // TODO: Encapsulate this in a way that works with the initializer rules
        let initialState: State
        if let token = (try? keychainToken.read()).flatMap({ $0 }) {
            initialState = .signedIn(AuthToken(token))
        } else {
            initialState = .signedOut
        }

        self.state = initialState
        self.webservice = webservice
        screen = LoginViewController(title: "Account", state: initialState)
        screen.requestAuthCode = { [unowned self] in self.requestAuthCode() }
        screen.verifyAuthCode = { [unowned self] authCode in self.verifyUserHasRegisteredAuthCode(authCode: authCode) }
        screen.signOut = { [unowned self] in self.signOut() }
    }

    public var authenticated: Bool {
        return state.authenticated
    }

    // TODO: Remove duplication between Login.State and this state.
    // This one handles the keychain while Login.State basically handles the rest.
    public private(set) var authenticationToken: AuthToken? {
        get {
            guard let token = (try? keychainToken.read()).flatMap({ $0 }) else { return nil }
            return AuthToken(token)
        }
        set {
            // These `try!`s should never fail, if they do, it's a programmer error and we trap.
            do {
                if let token = newValue {
                    try self.keychainToken.set(token.value)
                } else {
                    try self.keychainToken.delete()
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    private func requestAuthCode() {
        state = .requestingAuthCode
        webservice.load(AuthCode.requestAuthCode) { [unowned self] result in
            switch result {
            case .success(let authCode):
                self.state = .receivedAuthCode(authCode)
            case .error(let error):
                self.state = .requestingAuthCodeFailed(error)
            }
        }
    }

    private func verifyUserHasRegisteredAuthCode(authCode: AuthCode) {
        webservice.load(authCode.verifyAuthCode) { [unowned self] result in
            switch result {
            case .success(let response):
                self.state = .signedIn(response.token)
            case .error(let error):
                // TODO: Don't show an error once continuous polling is implemented.
                self.screen.presentAlert(message: "Could not verify your auth code. Please enter it in your web browser and try again. \(error.localizedDescription)")
            }
        }
    }

    private func signOut() {
        state = .signedOut
    }
}

extension Login.State {
    public var authenticated: Bool {
        if case .signedIn(_) = self { return true }
        else { return false }
    }

    public var authToken: AuthToken? {
        switch self {
        case .signedOut,
             .requestingAuthCode,
             .requestingAuthCodeFailed(_),
             .receivedAuthCode(_):
            return nil
        case .signedIn(let token):
            return token
        }
    }
}

extension Login.State: Equatable {
    public static func ==(lhs: Login.State, rhs: Login.State) -> Bool {
        switch (lhs, rhs) {
        case (.signedOut, .signedOut):
            return true
        case (.requestingAuthCode, .requestingAuthCode):
            return true
        case (.requestingAuthCodeFailed(_), .requestingAuthCodeFailed(_)):
            // Ignoring the associated Error values.
            return true
        case (.receivedAuthCode(let left), receivedAuthCode(let right)):
            return left == right
        case (.signedIn(let left), .signedIn(let right)):
            return left == right
        case (.signedOut, _),
             (.requestingAuthCode, _),
             (.requestingAuthCodeFailed, _),
             (.receivedAuthCode(_), _),
             (.signedIn(_), _):
            return false
        }
    }
}
