//
//  UserIdeaViewController.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import UIKit

class UserIdeaViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputBarBottomConstraint: NSLayoutConstraint!
    
    var currentStep: ChatStep = .waitingForIdea
    var messages: [Message] = []
    
    var userIdea: String = ""
    var selectedTone: String = ""
    var selectedPlatform: String = ""
    var refinement: String = ""
    
    var showAnalysisMessage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupKeyboardObservers()
        
        messages.append(Message(
            text: "Hello! I'm here to help turn your thoughts into viral posts. What's on your mind and on which platform do you plan to post on?",
            isUser: false,
            type: .text)
        )

        // Do any additional setup after loading the view.
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        tableView.register(UINib(nibName: "ChatOptionsTableViewCell", bundle: nil), forCellReuseIdentifier: "ChatOptionsTableViewCell")
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let text = messageTextField.text, !text.isEmpty else { return }
                
        // Clear text field
        messageTextField.text = ""
        
        // Pass the text to our Logic Handler
        handleUserResponse(text)
    }
    

        func handleUserResponse(_ responseText: String) {
            
            // 1. Show User's Message IMMEDIATELY
            let userMsg = Message(text: responseText, isUser: true, type: .text)
            messages.append(userMsg)
            insertNewMessage()
            
            // 2. Add a tiny delay (0.6s) to simulate "Thinking" and fix the UI glitch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self else { return }
                
                switch self.currentStep {
                    
                case .waitingForIdea:
                    self.userIdea = responseText
                    self.currentStep = .waitingForTone
                    
                    self.addBotResponse(
                        text: "Got it! What tone should the post have?",
                        options: ["Professional", "Casual", "Humorous", "Inspirational", "Bold"]
                    )
                    
                case .waitingForTone:
                    self.selectedTone = responseText
                    self.currentStep = .waitingForPlatform
                    
                    self.addBotResponse(
                        text: "And for which platform?",
                        options: ["LinkedIn", "Twitter/X", "Instagram"]
                    )
                    
                case .waitingForPlatform:
                    self.selectedPlatform = responseText
                    self.currentStep = .finished
                    self.fetchAIResponse()
                
                case .finished:
                    self.refinement = responseText
                    self.currentStep = .finished
                    
                    self.addBotResponse(
                        text: "Any other refinements you'd like?",
                        options: ["Make it more concise", "Strengthen the opening", "Add subtle expressiveness", "Reframe the post", "Include a Call to Action (CTA)"]
                    )
                    
                    self.addBotResponse(text: "here's your refined draft:")
                    self.fetchAIResponse()
                    print("Flow finished")
                    
                default:
                    break

                }
            }
        }

        // MARK: - Helper
        func addBotResponse(text: String, options: [String]? = nil) {
            var newIndexPaths: [IndexPath] = []
            
            // 1. Add Text
            let textMsg = Message(text: text, isUser: false, type: .text)
            messages.append(textMsg)
            newIndexPaths.append(IndexPath(row: messages.count - 1, section: 0))
            
            // 2. Add Options (if any)
            if let opts = options {
                let optsMsg = Message(text: "", isUser: false, type: .optionPills, options: opts)
                messages.append(optsMsg)
                newIndexPaths.append(IndexPath(row: messages.count - 1, section: 0))
            }
            
            // 3. Insert into Table View
            tableView.insertRows(at: newIndexPaths, with: .bottom)
            
            // 4. Scroll to bottom
            if let last = newIndexPaths.last {
                tableView.scrollToRow(at: last, at: .bottom, animated: true)
            }
        }
    
    
    func navigateToEditor(with draft: EditorDraftData) {
        if let editorVC = storyboard?.instantiateViewController(withIdentifier: "EditorSuiteViewController") as? EditorSuiteViewController {
            
            editorVC.draft = draft
            
            navigationController?.pushViewController(editorVC, animated: true)

        }
    }
}

extension UserIdeaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return messages.count
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        // ====================================================
        // PART 1: OPTION PILLS (The Collection View Cell)
        // ====================================================
        if message.type == .optionPills {
            
            // Dequeue the new cell we created (ensure identifier matches your XIB)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatOptionsTableViewCell", for: indexPath) as? ChatOptionsTableViewCell else {
                return UITableViewCell()
            }
            
            // Pass the array of strings (e.g. ["Casual", "Professional"])
            cell.configure(with: message.options ?? [])
            
            // handle logic when a pill is clicked
            cell.onOptionSelected = { [weak self] selectedText in
                // Pretend the user typed this text manually
                self?.handleUserResponse(selectedText)
            }
            
            return cell
        }
        
        // ====================================================
        // PART 2: TEXT BUBBLES (Standard Chat Cell)
        // ====================================================
        else {
            // Decide if it's a User (Right/Blue) or Bot (Left/Gray) cell
            let cellIdentifier = message.isUser ? "UserCell" : "BotCell"
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ChatCellTableViewCell else {
                return UITableViewCell()
            }
            
            // Setup bubble appearance
            cell.configureBubble(isUser: message.isUser)
            cell.messageLabel.text = message.text
            
            // Handle the "Open Editor" button (Only shows if there is a draft attached)
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
    }
    
    func insertNewMessage() {
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .bottom)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}


extension UserIdeaViewController {
    
    func fetchAIResponse() {
            // Construct the full prompt from our saved variables
            let fullQuery = "Idea: \(userIdea). Tone: \(selectedTone). Platform: \(selectedPlatform)."
            
        if !showAnalysisMessage {
            let loadingMessage = Message(text: "🔍 Generating your draft...", isUser: false, type: .text)
            messages.append(loadingMessage)
            insertNewMessage()
            showAnalysisMessage = true
        }
        

        Task {
            // Using a default profile for now, similar to your existing code
            let profile = await SupabaseManager.shared.fetchUserProfile() ?? UserProfile(
                role: ["General User"],
                industry: ["General"],
                primaryGoals: ["Growth"],
                contentFormats: ["Text"],
                toneOfVoice: [selectedTone], // Use the selected tone!
                targetAudience: ["Everyone"]
            )
            
            do {
                // Pass the combined query
                let draft = try await GeminiService.shared.generateDraft(idea: fullQuery, profile: profile)
                
                await MainActor.run {
                    self.handleSuccess(draft: draft)
                }
                
            } catch {
                await MainActor.run {
                    self.handleError(error: error)
                }
            }
        }
    }
    
    
    func handleSuccess(draft: EditorDraftData) {
        
        let platform = draft.platformName
        
        let isStrategy = platform.lowercased() == "strategy"

        
        let tags = draft.hashtags?.joined(separator: " ") ?? ""

        let displayText: String
        
        if isStrategy{
            displayText = draft.caption ?? "Here is the information you requested."
        } else {
            displayText = """
                ✨ Here is a draft:
                
                \(draft.caption ?? "No caption generated.")
                
                Hashtags:
                \(tags)
                """
        }
        

        let draftPayload = isStrategy ? nil : draft
               
        let aiMessage = Message(text: displayText, isUser: false, type: .text, draft: draftPayload)
               
        self.messages.append(aiMessage)
        self.insertNewMessage()
    }
        
        
        func handleError(error: Error) {
            print("AI Error: \(error.localizedDescription)")
            let errorMessage = Message(text: "⚠️ Couldn't generate a draft right now. Please check your connection.", isUser: false, type: .text)
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
        tapGesture.cancelsTouchesInView = false
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
