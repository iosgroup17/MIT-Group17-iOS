import UIKit
import Supabase
import AuthenticationServices

class ProfileViewController: UIViewController {

    /// Stores the one-time Apple authorization_code captured during re-auth.
    /// Forwarded to the Edge Function so Apple can revoke the credential.
    private var pendingAppleAuthCode: String?

    // image at the top
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var completionProgress: UIProgressView!
    // card backgrounds
    @IBOutlet weak var accountCardView: UIView!
    @IBOutlet weak var detailsCardView: UIView!
    @IBOutlet weak var socialCardView: UIView!
    @IBOutlet weak var progressCardView: UIView!
    @IBOutlet weak var settingsCardView: UIView!

    @IBOutlet weak var accountStack: UIStackView!
    @IBOutlet weak var detailsStack: UIStackView!
    @IBOutlet weak var socialStack: UIStackView!
    @IBOutlet weak var settingsStack: UIStackView!

    let store = OnboardingDataStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadGoogleProfileImage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data every time we appear (in case user returns from editing)
        loadData()
    }

    func setupUI() {
        // Round Image
        profileImageView.image = UIImage(named: "Avatar")
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemBackground.cgColor

        let cards = [accountCardView, detailsCardView, socialCardView, progressCardView, settingsCardView]
        for card in cards {
            if let c = card {
                c.applyHandleCardAppearance()
            }
        }
        // Style the Cards
        styleCard(accountCardView)
        styleCard(detailsCardView)
        styleCard(socialCardView)
        styleCard(settingsCardView)
    }

    func loadGoogleProfileImage() {
        // 1. Get the current user from Supabase
        guard let currentUser = SupabaseManager.shared.client.auth.currentUser else {
            return
        }

        // 2. Grab the metadata
        let metadata = currentUser.userMetadata

        // 3. Safely extract the avatar URL
        var avatarURLString: String?

        // Check standard Google image keys
        if let urlString = metadata["avatar_url"]?.value as? String {
            avatarURLString = urlString
        } else if let urlString = metadata["avatar_url"] as? String {
            avatarURLString = urlString
        } else if let urlString = metadata["picture"]?.value as? String {
            avatarURLString = urlString
        } else if let urlString = metadata["picture"] as? String {
            avatarURLString = urlString
        }

        // 4. Convert string to an actual URL
        guard let finalURLString = avatarURLString, let url = URL(string: finalURLString) else {
            return
        }

        // 5. Download the image asynchronously so we don't freeze the app
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {

                    // 6. Update the UI on the Main Thread
                    await MainActor.run {
                        self.profileImageView.image = downloadedImage
                    }
                }
            } catch {
            }
        }
    }

    func styleCard(_ view: UIView) {
        view.applyHandleCardAppearance()
    }

    func loadData() {
        Task {
            let remoteResponses = await SupabaseManager.shared.fetchUserOnboardingData()

            OnboardingDataStore.shared.syncWithRemoteData(remoteResponses)

            await MainActor.run {
                self.refreshUI()
            }
        }
    }

    func refreshUI() {
        let store = OnboardingDataStore.shared

        let teal = UIColor.systemTeal
        completionProgress.setProgress(store.completionPercentage, animated: true)

        [accountStack, detailsStack, socialStack, settingsStack].forEach { stack in
            stack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        }

        addRow(to: accountStack!, title: "Display Name", value: store.displayName ?? "Add Name") {
            self.showTextInput(title: "Edit Name", currentValue: store.displayName) { text in
                store.displayName = text; self.loadData()
            }
        }
        addRow(to: accountStack!, title: "Short Bio", value: store.shortBio ?? "Add Bio") {
            self.showTextInput(title: "Edit Bio", currentValue: store.shortBio) { text in
                store.shortBio = text; self.loadData()
            }
        }

        let goal = (store.userAnswers[0] as? [String])?.first ?? "Set Goal"
        addRow(to: detailsStack!, title: "Primary Goal", value: goal) { self.openEditor(forStep: 0) }

        let focus = (store.userAnswers[1] as? [String])?.first ?? "Set Focus"
        addRow(to: detailsStack!, title: "Professional Focus", value: focus) { self.openEditor(forStep: 1) }

        let expertise = (store.userAnswers[2] as? [String])?.first ?? "Set Expertise"
        addRow(to: detailsStack!, title: "Expertise", value: expertise) { self.openEditor(forStep: 2) }

        let audience = (store.userAnswers[3] as? [String])?.first
        addRow(to: socialStack!, title: "Target Audience", value: audience ?? "Boost Strategy") {
            self.openEditor(forStep: 3)
        }

        let platforms = (store.userAnswers[5] as? [String])?.joined(separator: ", ")
        addRow(to: socialStack!, title: "Platforms", value: platforms ?? "Boost Strategy") {
            self.openEditor(forStep: 5)
        }

        let tone = (store.userAnswers[6] as? [String])?.first
        addRow(to: socialStack!,
               title: "Brand Tone",
               value: tone ?? "Boost Strategy") {
            self.openEditor(forStep: 6)
        }

        let logoutIcon = UIImage(systemName: "rectangle.portrait.and.arrow.right")
        addRow(to: settingsStack!, title: "Logout", value: "", titleColor: .systemRed, iconImage: logoutIcon) { [weak self] in
            self?.showLogoutConfirmation()
        }

        let deleteIcon = UIImage(systemName: "trash")
        addRow(to: settingsStack!, title: "Delete Account", value: "", titleColor: .systemRed, iconImage: deleteIcon) { [weak self] in
            self?.showDeleteConfirmation()
        }

        [accountStack, detailsStack, socialStack, settingsStack].forEach { hideLastSeparator(in: $0!) }
    }

    func addRow(to stack: UIStackView, title: String, value: String, showIcon: Bool = true, titleColor: UIColor = .label, iconImage: UIImage? = nil, action: @escaping () -> Void) {
        let row = ProfileRow()
        row.configure(title: title, value: value, showIcon: showIcon, titleColor: titleColor, iconImage: iconImage)
        row.tapAction = action

        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stack.addArrangedSubview(row)
    }

    func showTextInput(title: String, currentValue: String?, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.text = currentValue
            textField.placeholder = "Enter here..."
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                completion(text)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    func hideLastSeparator(in stack: UIStackView) {
        if let lastRow = stack.arrangedSubviews.last as? ProfileRow {
            lastRow.separatorLine.isHidden = true
        }
    }

    func openEditor(forStep stepIndex: Int) {

        let storyboard = UIStoryboard(name: "Profile", bundle: nil)

        // instantiate onboardingVC here
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "OnboardingParentVC") as? OnboardingViewController else {
            return
        }

        // configure for editing 
        editorVC.currentStepIndex = stepIndex
        editorVC.isEditMode = true

        // present as sheet
        editorVC.onDismiss = { [weak self] in
            self?.loadData()
        }

        editorVC.modalPresentationStyle = .pageSheet
        if let sheet = editorVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        present(editorVC, animated: true)
    }

    func showLogoutConfirmation() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out of your account?", preferredStyle: .actionSheet)

        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.handleLogout()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(logoutAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    func handleLogout() {
        Task {
            try? await SupabaseManager.shared.client.auth.signOut()
            OnboardingDataStore.shared.reset()

            DispatchQueue.main.async {
                if let window = self.view.window,
                   window.windowScene?.delegate as? SceneDelegate != nil {

                    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginAuthVC")

                    window.rootViewController = loginVC

                    UIView.transition(with: window,
                                    duration: 0.3,
                                    options: .transitionCrossDissolve,
                                    animations: nil,
                                    completion: nil)
                }
            }
        }
    }

    // MARK: - Account Deletion

    func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This will permanently delete your account and all associated data. This cannot be undone.",
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(title: "Delete My Account", style: .destructive) { [weak self] _ in
            self?.initiateAccountDeletion()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }

    /// Entry point — checks whether the current user signed in with Apple and,
    /// if so, triggers a silent re-authentication to capture a fresh one-time
    /// authorization_code (required by Apple's server-side revocation API).
    private func initiateAccountDeletion() {
        guard let currentUser = SupabaseManager.shared.client.auth.currentUser else {
            deleteAccount(appleAuthorizationCode: nil)
            return
        }

        let isAppleUser = currentUser.appMetadata["provider"]?.value as? String == "apple"

        if isAppleUser {
            requestAppleAuthCodeThenDelete()
        } else {
            deleteAccount(appleAuthorizationCode: nil)
        }
    }

    /// Silently re-authenticates with Apple to obtain a fresh one-time
    /// authorization_code. The delegate callback forwards it to deleteAccount().
    private func requestAppleAuthCodeThenDelete() {
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        // No scopes needed — we only need the authorization_code for revocation
        request.requestedScopes = []

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate                   = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    /// Calls the `delete-user` Edge Function with the user's current session JWT.
    /// Passes the Apple authorization_code when available so the function can
    /// revoke the Apple credential server-side.
    private func deleteAccount(appleAuthorizationCode: String?) {
        Task {
            do {
                // Build the request body
                var body: [String: String] = [:]
                if let code = appleAuthorizationCode {
                    body["apple_authorization_code"] = code
                }

                // Invoke the delete-user Edge Function
                // The Supabase Swift client automatically attaches the current
                // session's JWT as the Authorization: Bearer header.
                let _: Void = try await SupabaseManager.shared.client.functions
                    .invoke(
                        "delete-user",
                        options: FunctionInvokeOptions(body: body.isEmpty ? nil : body)
                    )

                // Sign out locally and return to the login screen
                try? await SupabaseManager.shared.client.auth.signOut()
                OnboardingDataStore.shared.reset()

                await MainActor.run {
                    guard let window = self.view.window else { return }
                    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                    let loginVC    = storyboard.instantiateViewController(withIdentifier: "LoginAuthVC")
                    window.rootViewController = loginVC
                    UIView.transition(with: window,
                                      duration: 0.4,
                                      options: .transitionCrossDissolve,
                                      animations: nil)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Deletion Failed",
                        message: "Could not delete your account. Please try again later.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate (re-auth for Apple token revocation)

extension ProfileViewController: ASAuthorizationControllerDelegate,
                                  ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window ?? UIWindow()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let codeData   = credential.authorizationCode,
              let code       = String(data: codeData, encoding: .utf8)
        else {
            // Could not obtain code — proceed with deletion anyway (Apple-side
            // revocation will be skipped but auth.users will still be deleted)
            deleteAccount(appleAuthorizationCode: nil)
            return
        }

        deleteAccount(appleAuthorizationCode: code)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // The Apple re-auth step is ONLY for optional server-side token revocation.
        // The user already confirmed deletion intent via the destructive alert — so
        // regardless of what happens here (genuine cancel, simulator keychain error,
        // AKAuthenticationError Code=-7003 / ASAuthorizationError Code=1001, etc.)
        // we always proceed to delete from auth.users without the authorization_code.
        //
        // Distinguish for logging only:
        let nsError = error as NSError
        let hasUnderlyingSystemError = nsError.userInfo[NSUnderlyingErrorKey] != nil

        if hasUnderlyingSystemError {
            // System/keychain error (e.g. simulator AKAuthenticationError -7003).
            // Apple re-auth impossible in this environment — skip revocation, proceed.
            print("[DeleteAccount] ⚠️ Apple re-auth system error (skipping revocation): \(error.localizedDescription)")
        } else {
            // Genuine user-tapped-Cancel on the Apple sheet — but intent was already
            // confirmed; we still hard-delete from auth.users without revocation.
            print("[DeleteAccount] ⚠️ Apple re-auth cancelled by user (skipping revocation, proceeding with deletion)")
        }

        deleteAccount(appleAuthorizationCode: nil)
    }
}
