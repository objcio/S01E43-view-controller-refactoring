import UIKit

public final class LoginViewController: UIViewController {
    public var state: Login.State {
        didSet {
            guard state != oldValue else { return }
            DispatchQueue.main.async { self.updateUI() }
        }
    }

    // The view controller calls these functions to notify its owner of certain user interaction events.
    // TODO: Not all functions are valid for all states. Integrate into State? Or convert into delegate?
    /// User requests an auth code.
    public var requestAuthCode: (() -> ())?
    /// User asks to verify the registration (after they have entered the auth code in the web browser).
    /// - TODO: this should be automatic, without requiring user interaction (polling)
    public var verifyAuthCode: ((AuthCode) -> ())?
    /// User wants to sign out.
    public var signOut: (() -> ())?

    private let stack = UIStackView()

    public init(title: String, state: Login.State) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required public init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 40
        stack.layoutMargins = UIEdgeInsets(top: 100, left: 500, bottom: 100, right: 500)
        stack.isLayoutMarginsRelativeArrangement = true

        stack.centerXAnchor.constrainEqual(view.layoutMarginsGuide.centerXAnchor)
        stack.centerYAnchor.constrainEqual(view.layoutMarginsGuide.centerYAnchor)
        stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        stack.widthAnchor.constraint(greaterThanOrEqualToConstant: 600).isActive = true

        updateUI()
    }

    private func updateUI() {
        let rootView = userInterface(for: state)
        for view in stack.arrangedSubviews {
            view.removeFromSuperview()
        }
        stack.addArrangedSubview(rootView)
    }

    private func userInterface(for state: Login.State) -> UIView {
        switch state {
        case .signedOut:
            return UIStackView(content: [
                .button(title: "Sign In", callback: { [unowned self] in self.requestAuthCode?() })
            ])
        case .requestingAuthCode:
            let activityIndicator = UIActivityIndicatorView()
            activityIndicator.activityIndicatorViewStyle = .whiteLarge
            activityIndicator.startAnimating()
            return UIStackView(content: [
                ContentElement(text: "Requesting authentication code", alignment: .center),
                .custom(activityIndicator),
            ])
        case .requestingAuthCodeFailed(let error):
            return UIStackView(content: [
                ContentElement(text: "An error occurred. Please try again later. \(error.localizedDescription)", alignment: .center),
                .button(title: "Retry", callback: { [unowned self] in self.requestAuthCode?() }),
            ])
        case .receivedAuthCode(let authCode):
            return UIStackView(content: [
                ContentElement(text: "Your auth code is:", style: .callout, alignment: .center),
                ContentElement(text: authCode.code, style: .headline, alignment: .center),
                ContentElement(text: "Go to https://talk.objc.io/verify on your mobile device or computer and enter this code.", style: .callout, alignment: .center),
                .button(title: "I have entered the code", callback: { [unowned self] in self.verifyAuthCode?(authCode) }),
                .button(title: "Request a new code", callback: { [unowned self] in self.requestAuthCode?() }),
            ])
        case .signedIn(_):
            return UIStackView(content: [
                ContentElement(text: "You are signed in.", style: .callout, alignment: .center),
                .button(title: "Sign Out", callback: { self.signOut?() })
            ])
        }
    }
}
