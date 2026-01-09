//
//  UserIdeaViewController.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import UIKit

struct Message {
    let text: String
    let isUser: Bool // true = User, false = AI
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
        
        messages.append(Message(text: "Hello! I'm here to help turn your thoughts into viral posts. What's on your mind?", isUser: false))

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
}

extension UserIdeaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return messages.count
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cellIdentifier = message.isUser ? "UserCell" : "BotCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = message.text
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
                profession: ["General User"],
                targetAudience: ["Everyone"],
                contentGoals: ["Growth"],
                toneOfVoice: ["Friendly"],
                contentTopics: ["Lifestyle"],
                preferredPlatforms: ["Instagram"]
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
            
            // Create a structured text response
            let displayText = """
            ✨ Here is a draft for \(platform):
            
            \(draft.caption ?? "No caption generated.")
            
            Hashtags:
            \(tags)
            """
            
            let aiMessage = Message(text: displayText, isUser: false)
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
