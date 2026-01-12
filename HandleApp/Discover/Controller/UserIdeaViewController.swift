//
//  UserIdeaViewController.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import UIKit

struct Message {
    let text: String
    let isUser: Bool
    var draft: EditorDraftData? = nil
}

class UserIdeaViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputBarBottomConstraint: NSLayoutConstraint!
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupKeyboardObservers()
        
        messages.append(Message(text: "Hello! I'm here to help turn your thoughts into viral posts. What's on your mind and on which platform do you plan to post on?", isUser: false))

        // Do any additional setup after loading the view.
    }
    
    func setupTableView() {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        
        // 1. Add User Message
        let userMessage = Message(text: text, isUser: true)
        messages.append(userMessage)
        
        // 2. Refresh UI
        insertNewMessage()
        messageTextField.text = ""
        
        // 3. Trigger AI
        fetchAIResponse(for: text)
    }
    
    func navigateToEditor(with draft: EditorDraftData) {
        print("🚀 Moving to Editor with caption: \(draft.caption ?? "")")
        
        
        // Option A: If using Storyboard ID
        if let editorVC = storyboard?.instantiateViewController(withIdentifier: "EditorSuiteViewController") as? EditorSuiteViewController {
            
            // Pass the data!
            // editorVC.draftData = draft
            
            navigationController?.pushViewController(editorVC, animated: true)
            // Or if using modal: present(editorVC, animated: true)
        }
    }
}

extension UserIdeaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return messages.count
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cellIdentifier = message.isUser ? "UserCell" : "BotCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ChatCellTableViewCell else {
                return UITableViewCell()
            }
        
        cell.messageLabel.text = message.text
        
        if let btn = cell.editorButton {
            if let draftData = message.draft {
                btn.isHidden = false
                cell.onEditorButtonTapped = { [weak self] in
                    self?.navigateToEditor(with: draftData)
                }
            } else {
                btn.isHidden = true
            }
        } 
        
        return cell
    }
    
    func insertNewMessage() {
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .bottom)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}


extension UserIdeaViewController {
    
    func fetchAIResponse(for query: String) {
        
        // 1. Show "Thinking" state immediately
        let loadingMessage = Message(text: "🔍 Analyzing your profile and generating ideas...", isUser: false)
        messages.append(loadingMessage)
        insertNewMessage()
        
        Task {
            // 2. Fetch User Profile from Supabase (Waits here)
            // Note: If fetchUserProfile returns nil, we use a fallback default profile so the app doesn't crash.
            let profile = await SupabaseManager.shared.fetchUserProfile() ?? UserProfile(
                    role: ["General User"],
                    industry: ["General"],
                    primaryGoals: ["Growth"],
                    contentFormats: ["Text"],
                    toneOfVoice: ["Friendly"],
                    targetAudience: ["Everyone"]
                )
            
            // 3. Call AI Service (OpenRouter)
            OpenRouterService.shared.generateDraft(idea: query, profile: profile) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    // Remove the "Thinking..." message (optional, or just add new one below)
                    // For simplicity, we just add the result at the bottom.
                    
                    switch result {
                    case .success(let draft):
                        self.handleSuccess(draft: draft)
                        
                    case .failure(let error):
                        self.handleError(error: error)
                    }
                }
            }
        }
    }
    func handleSuccess(draft: EditorDraftData) {
        let platform = draft.platformName
        let tags = draft.hashtags?.joined(separator: " ") ?? ""
        
        let displayText = """
        ✨ Here is a draft for \(platform):
        
        \(draft.caption ?? "No caption generated.")
        
        Hashtags:
        \(tags)
        """
        
        // ✅ Store the draft object here!
        let aiMessage = Message(text: displayText, isUser: false, draft: draft)
        
        self.messages.append(aiMessage)
        self.insertNewMessage()
    }
        
        func handleError(error: Error) {
            print("AI Error: \(error.localizedDescription)")
            let errorMessage = Message(text: "⚠️ I couldn't generate a draft right now. Please check your connection.", isUser: false)
            self.messages.append(errorMessage)
            self.insertNewMessage()
        }
    }

extension UserIdeaViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // Check if the return key was pressed on the message text field
            if textField == messageTextField {
                sendButtonTapped(textField) // Trigger the existing send logic
                return false // Return false so it doesn't try to insert a new line
            }
            return true
        }
    
    func setupKeyboardObservers() {
        messageTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tableView.addGestureRecognizer(tapGesture)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomPadding = view.safeAreaInsets.bottom
            inputBarBottomConstraint.constant = keyboardSize.height - bottomPadding
            UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
            
            if !messages.isEmpty {
                let indexPath = IndexPath(row: messages.count - 1, section: 0)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        inputBarBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
