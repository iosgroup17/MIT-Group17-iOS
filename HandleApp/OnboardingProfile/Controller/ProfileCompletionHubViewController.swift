import UIKit

/// Modal "Complete your profile" hub opened from the home-screen card.
/// Lists every profile item with a checkmark; tapping a row lets the user fill
/// it in (text input for name/bio, the existing onboarding editor for steps).
/// Reports edits back via `onChange` so the card can refresh.
final class ProfileCompletionHubViewController: UITableViewController {

    /// Called after any successful edit so the presenter can refresh the card.
    var onChange: (() -> Void)?

    private let items = ProfileChecklist.items

    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Complete Your Profile"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChecklistCell")
        tableView.tableHeaderView = makeHeader()
        refreshHeader()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Header

    private func makeHeader() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 96))

        let titleLabel = UILabel()
        titleLabel.text = "A complete profile gives you sharper, more relevant post suggestions."
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        progressBar.progressTintColor = UIColor.systemTeal
        progressBar.trackTintColor = UIColor.systemGray5
        progressBar.layer.cornerRadius = 2
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.heightAnchor.constraint(equalToConstant: 6).isActive = true

        progressLabel.font = .preferredFont(forTextStyle: .caption1)
        progressLabel.textColor = .secondaryLabel
        progressLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(progressBar)
        container.addSubview(progressLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            progressBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 6),
            progressLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            progressLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    /// Size the table header to fit its content (avoids clipping under large text).
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let target = CGSize(width: tableView.bounds.width,
                            height: UIView.layoutFittingCompressedSize.height)
        let fitted = header.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if abs(header.frame.height - fitted.height) > 0.5 {
            header.frame.size.height = fitted.height
            tableView.tableHeaderView = header
        }
    }

    private func refreshHeader() {
        let done = ProfileChecklist.completedCount
        let total = ProfileChecklist.totalCount
        progressBar.setProgress(ProfileChecklist.fractionComplete, animated: true)
        progressLabel.text = ProfileChecklist.isComplete
            ? "All set — your profile is complete!"
            : "\(done) of \(total) completed"
    }

    /// Reload rows + header and notify the presenter.
    private func reloadAfterEdit() {
        tableView.reloadData()
        refreshHeader()
        onChange?()
    }

    // MARK: - Table data

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChecklistCell", for: indexPath)
        let item = items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.currentValue ?? "Not set yet"
        content.secondaryTextProperties.color = item.isComplete ? .secondaryLabel : .systemTeal
        cell.contentConfiguration = content

        if item.isComplete {
            let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            check.tintColor = .systemGreen
            cell.accessoryView = check
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    // MARK: - Editing

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        switch item {
        case .displayName:
            editText(title: "Display Name", current: OnboardingDataStore.shared.displayName) { value in
                OnboardingDataStore.shared.displayName = value
            }
        case .shortBio:
            editText(title: "Short Bio", current: OnboardingDataStore.shared.shortBio) { value in
                OnboardingDataStore.shared.shortBio = value
            }
        case .step(let stepIndex):
            editStep(stepIndex)
        }
    }

    private func editText(title: String, current: String?, save: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Edit \(title)", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = current
            field.placeholder = "Enter \(title.lowercased())..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            save(text)
            self?.reloadAfterEdit()
        })
        present(alert, animated: true)
    }

    private func editStep(_ stepIndex: Int) {
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        guard let editorVC = storyboard.instantiateViewController(
            withIdentifier: "OnboardingParentVC") as? OnboardingViewController else {
            return
        }

        editorVC.currentStepIndex = stepIndex
        editorVC.isEditMode = true
        editorVC.onDismiss = { [weak self] in
            self?.reloadAfterEdit()
        }

        editorVC.modalPresentationStyle = .pageSheet
        if let sheet = editorVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(editorVC, animated: true)
    }
}
