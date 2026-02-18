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

        messageTextField.text = ""
        
        handleUserResponse(text)
    }
    

        func handleUserResponse(_ responseText: String) {
            
            let userMsg = Message(text: responseText, isUser: true, type: .text)
            messages.append(userMsg)
            insertNewMessage()
     
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self else { return }
                
                switch self.currentStep {
                    
                case .waitingForIdea:
                    self.userIdea = responseText
                    self.currentStep = .waitingForTone
                    
                    self.addBotResponse(
                        text: "Got it! What tone should the post have?",
                        options: [
                            "Professional",
                            "Educational",
                            "Casual",
                            "Direct",
                            "Analytical",
                            "Contrarian",
                            "Conversational",
                            "Inspirational",
                            "Storytelling"

                        ]
                    )
                    
                case .waitingForTone:
                    self.selectedTone = responseText
                    self.currentStep = .waitingForPlatform
                    
                    self.addBotResponse(
                        text: "And for which platform?",
                        options: ["LinkedIn", "X", "Instagram"]
                    )
                    
                case .waitingForPlatform:
                    self.selectedPlatform = responseText
                    self.currentStep = .waitingForRefinement
                    self.fetchAIResponse()

                case .waitingForRefinement:
                    self.refinement = responseText
                    self.currentStep = .finished
                    self.showAnalysisMessage = false
                    self.fetchAIResponse()

                default:
                    break

                }
            }
        }

    
        func addBotResponse(text: String, options: [String]? = nil) {
            var newIndexPaths: [IndexPath] = []
            
            
            let textMsg = Message(text: text, isUser: false, type: .text)
            messages.append(textMsg)
            newIndexPaths.append(IndexPath(row: messages.count - 1, section: 0))
            

            if let opts = options {
                let optsMsg = Message(text: "", isUser: false, type: .optionPills, options: opts)
                messages.append(optsMsg)
                newIndexPaths.append(IndexPath(row: messages.count - 1, section: 0))
            }
            

            tableView.insertRows(at: newIndexPaths, with: .bottom)
            

            if let last = newIndexPaths.last {
                tableView.scrollToRow(at: last, at: .bottom, animated: true)
            }
        }
    
    
    func navigateToEditor(with draft: EditorDraftData) {
        if let editorVC = storyboard?.instantiateViewController(withIdentifier: "EditorModalEntry") as? EditorSuiteViewController {
            
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
        
    
        if message.type == .optionPills {
            

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatOptionsTableViewCell", for: indexPath) as? ChatOptionsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: message.options ?? [])
            

            cell.onOptionSelected = { [weak self] selectedText in

                self?.handleUserResponse(selectedText)
            }
            
            return cell
        }
        
      
        else {
  
            let cellIdentifier = message.isUser ? "UserCell" : "BotCell"
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ChatCellTableViewCell else {
                return UITableViewCell()
            }
            

            cell.configureBubble(isUser: message.isUser)
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
    }
    
    func insertNewMessage() {
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .bottom)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}


extension UserIdeaViewController {
    
    func fetchAIResponse() {
            if !showAnalysisMessage {
                let loadingMessage = Message(text: "🔍 Analyzing your profile & generating draft...", isUser: false, type: .text)
                messages.append(loadingMessage)
                insertNewMessage()
                showAnalysisMessage = true
            }

            Task {
                do {
                    // 1. Fetch the REAL profile from Supabase & Local JSON
                    // This now includes professionalIdentity, goals, and acceptedSuggestions
                    guard let profileContext = await SupabaseManager.shared.fetchUserProfile() else {
                        throw NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not load user profile."])
                    }

                    // 2. Prepare the request
                    let request = GenerationRequest(
                        idea: self.userIdea,
                        tone: self.selectedTone,
                        platform: self.selectedPlatform,
                        refinementInstruction: self.refinement.isEmpty ? nil : self.refinement
                    )
                
                    // 3. Generate the post using the full context
                    let draft = try await PostGenerationModel.shared.generatePost(
                        profile: profileContext,
                        request: request
                    )

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
        
        if self.currentStep == .waitingForRefinement {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                    self?.addBotResponse(
                        text: "Any refinements you'd like to make to this draft?",
                        options: [
                            "Make the post more concise",
                            "Strengthen the opening hook",
                            "Reframe with sharper clarity"
                        ]
                    )
                }
            }
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

            if textField == messageTextField {
                sendButtonTapped(textField)
                return false 
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
