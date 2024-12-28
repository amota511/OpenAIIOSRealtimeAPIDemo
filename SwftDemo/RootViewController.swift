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
    private var remainingTime = 300 // 5:00 in seconds
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "5:00"
        label.font = UIFont.boldSystemFont(ofSize: 80)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GlobalColors.mainBackground
        
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
                title: "The websocket is connected. Disconnect?",
                message: "",
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let confirAction = UIAlertAction(title: "Confirm", style: .default) { alert in
                WebSocketManager.shared.audio_String = ""
                WebSocketManager.shared.audio_String_count = 0
                PlayAudioCotinuouslyManager.shared.audio_event_Queue.removeAll()
                RecordAudioManager.shared.pauseCaptureAudio()
                WebSocketManager.shared.socket.disconnect()

                // Summarize conversation after session ends
                self.summarizeDailyConversation()
            }
            alertVC.addAction(cancelAction)
            alertVC.addAction(confirAction)
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
            remainingTime = 300
            timerLabel.text = "5:00"

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
        
        // Stub for sending conversation to ChatGPT (or other summarizing service).
        // Currently just prints a placeholder summary.
        print("Sending conversation to ChatGPT for summary:\n\(conversation)")
        print("ChatGPT summary of the day: [Placeholder summary response here]")
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

