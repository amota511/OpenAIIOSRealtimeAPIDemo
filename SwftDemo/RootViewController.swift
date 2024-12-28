import UIKit

class RootViewController: UIViewController {

    lazy var audioVolumeView = {
        let view = AudioVisualizerView(frame:.zero)

        view.backgroundColor = .clear
        return view
    }()
    
    let startSessionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Check-In", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.backgroundColor = GlobalColors.primaryButton
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let monitorAudioDataView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tableItems = ["Gallon of water", "10K steps", "Eat clean", "Gym", "Meditate", "Alcohol", "Bad Sleep", "Overspend", "Sick day"]
    
    private let partialBlurTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()
    
    private let bottomBlurView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    // 1) Keep track of which rows have a "selected" bubble
    private var selectedBubbles = Set<Int>()
    
    // 1) Add a new Set to remember which rows have a rotated chevron
    private var rotatedChevrons = Set<Int>()
    
    private let profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.crop.circle"), for: .normal)
        button.tintColor = GlobalColors.primaryText
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 1) Add properties for timer logic
    private var sessionTimer: Timer?
    private var remainingTime = 120 // 2:00 in seconds
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "2:00"
        label.font = UIFont.boldSystemFont(ofSize: 80)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Provide a structure to parse the GPT response (only if you don't already parse it)
    private struct ChatCompletionResponse: Decodable {
        let choices: [Choice]
        struct Choice: Decodable {
            let message: Message
        }
        struct Message: Decodable {
            let content: String
        }
    }

    // A struct matching the "Stories" format from ProgressViewController
    private struct StoryItem: Codable {
        let date: String
        let story: String
    }

    private let oneDayInterval = 24.0 * 60.0 * 60.0

    // Store summarized text in UserDefaults with an existing array, under key "Stories"
    private func storeSummarizedStory(_ summary: String) {
        // Define a new StoryItem
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        let newStory = StoryItem(date: formatter.string(from: Date()), story: summary)

        // Load existing stories
        let defaults = UserDefaults.standard
        var items: [StoryItem] = []
        if let data = defaults.data(forKey: "Stories"),
           let decoded = try? JSONDecoder().decode([StoryItem].self, from: data) {
            items = decoded
        } else {
            print("Failed to decode summarized result")
        }

        // Append and save
        items.append(newStory)
        if let updatedData = try? JSONEncoder().encode(items) {
            defaults.set(updatedData, forKey: "Stories")
            print("Stored Summarized result")
        } else {
            print("Couldn't store summarized result")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GlobalColors.mainBackground
        
        // Initially set up the session button state
        updateCheckInButton()
        
        view.addSubview(timerLabel)
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        view.addSubview(monitorAudioDataView)
        monitorAudioDataView.addSubview(audioVolumeView)
        
        NSLayoutConstraint.activate([
            monitorAudioDataView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            monitorAudioDataView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            monitorAudioDataView.widthAnchor.constraint(equalToConstant: 200),
            monitorAudioDataView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Ensure audioVolumeView is centered horizontally and vertically
        audioVolumeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            audioVolumeView.centerXAnchor.constraint(equalTo: monitorAudioDataView.centerXAnchor),
            audioVolumeView.centerYAnchor.constraint(equalTo: monitorAudioDataView.centerYAnchor)
        ])
        
        startSessionButton.addTarget(self, action: #selector(clickSessionButton(_:)), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(openAiStatusChanged), name: NSNotification.Name(rawValue: "WebSocketManager_connected_status_changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showMonitorAudioDataView(notification:)), name: NSNotification.Name(rawValue: "showMonitorAudioDataView"), object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAIIsPlayingAudio),
            name: NSNotification.Name("AIIsPlayingAudioDelta"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserStartToSpeak),
            name: NSNotification.Name(rawValue: "UserStartToSpeek"),
            object: nil
        )
        
        if #available(iOS 14.0, *) {
            let feedbackAction = UIAction(title: "Leave feedback") { _ in
                // Handle feedback
            }
//            let manageSubscriptionAction = UIAction(title: "Manage Subscription") { _ in
//                // Handle feedback
//            }
            let logoutAction = UIAction(title: "Log out", attributes: .destructive) { _ in
                // Handle log out
            }
            let menu = UIMenu(title: "", children: [feedbackAction, logoutAction])
            profileButton.menu = menu
            profileButton.showsMenuAsPrimaryAction = true
        } else {
            profileButton.addTarget(self, action: #selector(showFallbackMenu), for: .touchUpInside)
        }
        
        startSessionButton.removeFromSuperview()
        view.addSubview(startSessionButton)
        NSLayoutConstraint.activate([
            startSessionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            startSessionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            startSessionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            startSessionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bottomBlurView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let gradient = CAGradientLayer()
        gradient.frame = bottomBlurView.bounds
        
        gradient.colors = [
            GlobalColors.mainBackground.withAlphaComponent(0.2).cgColor,
            GlobalColors.mainBackground.withAlphaComponent(1.0).cgColor
        ]
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1.0)
        bottomBlurView.layer.addSublayer(gradient)
    }
    
    @objc func clickSessionButton(_ sender: Any) {
        if WebSocketManager.shared.connected_status == "connected" {
            sessionTimer?.invalidate()
            sessionTimer = nil
            
            let alertVC = UIAlertController(
                title: "Are you sure you want to end the session?",
                message: "",
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let endSessionAction = UIAlertAction(title: "End Session", style: .default) { alert in
                WebSocketManager.shared.audio_String = ""
                WebSocketManager.shared.audio_String_count = 0
                PlayAudioCotinuouslyManager.shared.audio_event_Queue.removeAll()
                RecordAudioManager.shared.pauseCaptureAudio()
                WebSocketManager.shared.socket.disconnect()

                // Summarize conversation after session ends
                self.summarizeDailyConversation()
            }
            alertVC.addAction(cancelAction)
            alertVC.addAction(endSessionAction)
            getCurrentVc().present(alertVC, animated: true)
        } else {
            // 3) Remove auto-start here
            // startTimer() <-- removed
            WebSocketManager.shared.connectWebSocketOfOpenAi()
        }
    }
    
    @objc func openAiStatusChanged() {
        if WebSocketManager.shared.connected_status == "not_connected" {
            startSessionButton.setTitle("Start Check-in", for: .normal)
        } else if WebSocketManager.shared.connected_status == "connecting" {
            startSessionButton.setTitle("Connecting...", for: .normal)
        } else if WebSocketManager.shared.connected_status == "connected" {
            // Reset the timer when the connection is established
            sessionTimer?.invalidate()
            sessionTimer = nil
            remainingTime = 120        // Use 120 for 2 minutes
            timerLabel.text = "2:00"   // Update the label text too

            startTimer()
            startSessionButton.setTitle("End Check-in", for: .normal)
        } else {
            startSessionButton.setTitle("", for: .normal)
        }
    }
    
    @objc func showMonitorAudioDataView(notification: Notification){
        if let dict = notification.object as? [String: Any] {
            if let rmsValue = dict["rmsValue"] as? Float{
                //print("This volume is:\(rmsValue)")
                DispatchQueue.main.async {
                    self.audioVolumeView.updateCircles(with: rmsValue)
                }
            }
        }
    }
    
    @objc func handleAIIsPlayingAudio() {
        // Trigger the visualizer animation
        self.audioVolumeView.animateAiSpeaking()
    }
    
    @objc func handleUserStartToSpeak() {
        // Reset the circles to black/white
        audioVolumeView.resetCirclesForUserSpeaking()
    }
    
    @objc private func showFallbackMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let feedbackAction = UIAlertAction(title: "Leave feedback", style: .default) { _ in
            // Handle feedback
        }
        let logoutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            // Handle log out
        }
        alertController.addAction(feedbackAction)
        alertController.addAction(logoutAction)
        // If on iPad, configure popover sourceRect/sourceView for a popover
        present(alertController, animated: true)
    }
    
    // 6) Timer utility functions
    private func startTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                            selector: #selector(updateTimer),
                                            userInfo: nil,
                                            repeats: true)
    }

    @objc private func updateTimer() {
        if remainingTime > 0 {
            remainingTime -= 1
            let minutes = remainingTime / 60
            let seconds = remainingTime % 60
            timerLabel.text = String(format: "%d:%02d", minutes, seconds)
        } else {
            sessionTimer?.invalidate()
            sessionTimer = nil
            // 3) End the real-time connection
            WebSocketManager.shared.socket.disconnect()

            // Summarize conversation after timer ends
            summarizeDailyConversation()

            // 4) Disable the Start Session button
            startSessionButton.isEnabled = false
        }
    }

    // Add a helper to send conversation off for summarizing
    private func summarizeDailyConversation() {
        let conversation = WebSocketManager.shared.getAllConversationText()

        // Remove (or retain if you like) the local print statements:
        // print("Sending conversation to ChatGPT for summary:\n\(conversation)")
        // print("ChatGPT summary of the day: [Placeholder summary response here]")

        // Replace with an actual call to OpenAI (example for gpt-3.5-turbo)
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid URL")
            return
        }

        let messages: [[String: Any]] = [
            ["role": "user",   "content": "Please summarize how the user did for the day, based on this conversation:\n\(conversation)"]
        ]

        let requestBody: [String: Any] = [
            "model": "o1-mini",
            "messages": messages
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(openAiApiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Request error: \(error)")
                    return
                }
                guard let data = data else {
                    print("No response data received")
                    return
                }

                do {
                    // Attempt to parse the OpenAI Chat Completions response
                    let decodedResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                    if let firstContent = decodedResponse.choices.first?.message.content {
                        // 1) Print or handle the summarized text 
                        print("OpenAI summarized response:\n\(firstContent)")

                        // 2) Store it in UserDefaults in "Stories" format
                        self.storeSummarizedStory(firstContent)

                        // 2) After a successful session, store the lastCheckIn time
                        UserDefaults.standard.set(Date(), forKey: "lastCheckIn")
                        
                        // 3) Re-check the button state on the main thread
                        DispatchQueue.main.async {
                            self.updateCheckInButton()
                        }
                    }
                } catch {
                    // If decoding fails, just print raw text as fallback
                    print("Failed to decode chat completion. Raw:\n\(String(data: data, encoding: .utf8) ?? "")")
                }
            }.resume()

        } catch {
            print("JSON serialization error: \(error)")
        }
    }

    // 1) Factor out the logic to check lastCheckIn
    private func updateCheckInButton() {
        let defaults = UserDefaults.standard
        if let lastCheckIn = defaults.object(forKey: "lastCheckIn") as? Date {
            // 1) Check if lastCheckIn is the same calendar day as now
            if Calendar.current.isDate(lastCheckIn, inSameDayAs: Date()) {
                // If the last check-in is on the same day, disable the button
                startSessionButton.isEnabled = false
                startSessionButton.setTitle("Already checked in", for: .normal)
                startSessionButton.backgroundColor = .lightGray
            } else {
                // Different calendar day; let them start a new session
                startSessionButton.isEnabled = true
                startSessionButton.setTitle("Start Check-in", for: .normal)
                startSessionButton.backgroundColor = GlobalColors.primaryButton
            }
        } else {
            // No prior session at all
            startSessionButton.isEnabled = true
            startSessionButton.setTitle("Start Check-in", for: .normal)
            startSessionButton.backgroundColor = GlobalColors.primaryButton
        }
    }
}

extension RootViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "partialBlurCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
            ?? UITableViewCell(style: .default, reuseIdentifier: cellId)
        
        cell.selectionStyle = .none
        
        cell.textLabel?.text = tableItems[indexPath.row]
        cell.textLabel?.textColor = GlobalColors.primaryText
        
        cell.backgroundColor = GlobalColors.mainBackground
        
        let BUBBLE_TAG = 9999
        // Remove old bubble if reusing cell
        if let existingBubble = cell.contentView.viewWithTag(BUBBLE_TAG) {
            existingBubble.removeFromSuperview()
        }
        
        let bubbleDiameter: CGFloat = 14
        let bubbleView = UIView(frame: CGRect(
            x: 0,
            y: (50 - bubbleDiameter) / 2,
            width: bubbleDiameter,
            height: bubbleDiameter
        ))
        bubbleView.layer.cornerRadius = bubbleDiameter / 2
        bubbleView.layer.borderWidth = 1
        bubbleView.tag = BUBBLE_TAG
        
        // Check if bubble is selected
        if selectedBubbles.contains(indexPath.row) {
            bubbleView.backgroundColor = .systemGreen
            bubbleView.layer.borderColor = UIColor.clear.cgColor
        } else {
            bubbleView.backgroundColor = .clear
            bubbleView.layer.borderColor = UIColor.gray.cgColor
        }
        
        cell.contentView.addSubview(bubbleView)
        
        // 2) Add the chevron icon on the right side
        let CHEVRON_TAG = 9998
        if let existingChevron = cell.contentView.viewWithTag(CHEVRON_TAG) {
            existingChevron.removeFromSuperview()
        }
        
        // Use systemName chevron.down
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.tag = CHEVRON_TAG

        // 3) If this row is rotated, rotate the chevron 180 degrees
        if rotatedChevrons.contains(indexPath.row) {
            chevronImageView.transform = CGAffineTransform(rotationAngle: .pi)
        } else {
            chevronImageView.transform = .identity
        }

        // 4) Make chevron tappable
        chevronImageView.isUserInteractionEnabled = true
        let tapChevronGesture = UITapGestureRecognizer(target: self, action: #selector(handleChevronTap(_:)))
        chevronImageView.addGestureRecognizer(tapChevronGesture)
        chevronImageView.accessibilityHint = "\(indexPath.row)"

        // 5) Increase chevron size
        cell.contentView.addSubview(chevronImageView)
        NSLayoutConstraint.activate([
            chevronImageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 24),
            chevronImageView.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        chevronImageView.tintColor = GlobalColors.primaryText
        
        return cell
    }
    
    // Toggle the bubble when the user taps the cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedBubbles.contains(indexPath.row) {
            selectedBubbles.remove(indexPath.row)
        } else {
            selectedBubbles.insert(indexPath.row)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }

}

// 6) Toggle chevron rotation
extension RootViewController {
    @objc private func handleChevronTap(_ gesture: UITapGestureRecognizer) {
        guard let chevron = gesture.view as? UIImageView,
              let rowString = chevron.accessibilityHint,
              let row = Int(rowString) else {
            return
        }
        
        // Determine if it's currently rotated
        let isRotated = rotatedChevrons.contains(row)
        
        // Animate the rotation transform in-place
        UIView.animate(withDuration: 0.4) {
            if isRotated {
                self.rotatedChevrons.remove(row)
                chevron.transform = CGAffineTransform(rotationAngle: 2 * .pi)
            } else {
                self.rotatedChevrons.insert(row)
                chevron.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
    }
}

