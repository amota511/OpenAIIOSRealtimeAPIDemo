import UIKit
import AVFoundation
import AVFAudio

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
        label.textColor = GlobalColors.primaryText
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
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

    // Add a property for RealTimeApiWebRTCMainVC
    private var realTimeAPI = RealTimeApiWebRTCMainVC()

    // Add this property to track check-ins
    private struct DailyCheckIn: Codable {
        let date: Date
        var summary: String?
    }

    // Add helper methods for managing check-in state
    private func saveTodayCheckIn(summary: String? = nil) {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        
        var checkIns: [DailyCheckIn] = []
        if let data = defaults.data(forKey: "DailyCheckIns"),
           let decoded = try? JSONDecoder().decode([DailyCheckIn].self, from: data) {
            checkIns = decoded
        }
        
        // Remove existing check-in for today if it exists
        checkIns.removeAll { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        // Add new check-in
        checkIns.append(DailyCheckIn(date: today, summary: summary))
        
        // Save updated check-ins
        if let encoded = try? JSONEncoder().encode(checkIns) {
            defaults.set(encoded, forKey: "DailyCheckIns")
        }
    }

    private func hasCheckedInToday() -> Bool {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        
        guard let data = defaults.data(forKey: "DailyCheckIns"),
              let checkIns = try? JSONDecoder().decode([DailyCheckIn].self, from: data) else {
            return false
        }
        
        return checkIns.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

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
    
    // 1) Add properties to handle metering
    private var audioRecorder: AVAudioRecorder?
    private var audioLevelTimer: Timer?
    
    // 2) Start local mic monitoring to animate audioVolumeView
    private func startMonitoringUserAudio() {
        // Add robust error handling and logging
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch audioAuthStatus {
        case .notDetermined:
            print("Audio permission not determined, requesting...")
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    print("Audio permission granted")
                    DispatchQueue.main.async {
                        self.setupAudioSession()
                        self.startMonitoringUserAudio()
                    }
                } else {
                    print("Audio permission denied")
                    DispatchQueue.main.async {
                        self.handleAudioPermissionDenied()
                    }
                }
            }
            return
        
        case .denied, .restricted:
            print("Audio permission denied/restricted")
            handleAudioPermissionDenied()
            return
        
        case .authorized:
            print("Audio permission already authorized")
            setupAudioSession()
            continueAudioMonitoring()
        
        @unknown default:
            print("Unknown audio permission status")
            handleAudioPermissionDenied()
            return
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for both playback and recording
            try audioSession.setCategory(.playAndRecord,
                                       mode: .default,
                                       options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker, .mixWithOthers])
            
            // Set preferred sample rate and buffer duration
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
            
            // Activate the audio session
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("Audio session setup successful")
            
            // Ensure audio is routed to speaker
            try audioSession.overrideOutputAudioPort(.speaker)
            
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    private func continueAudioMonitoring() {
        let settings: [String: Any] = [
            AVSampleRateKey: 44100.0,
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            guard let recorderUrl = URL(string: "/dev/null") else {
                print("Failed to create recorder URL")
                return
            }
            
            let recorder = try AVAudioRecorder(url: recorderUrl, settings: settings)
            self.audioRecorder = recorder
            recorder.isMeteringEnabled = true
            
            if recorder.prepareToRecord() && recorder.record() {
                print("Successfully started audio recording/monitoring")
                setupAudioLevelTimer()
            } else {
                print("Failed to start audio recording")
            }
        } catch {
            print("Error creating audio recorder: \(error.localizedDescription)")
        }
    }
    
    private func handleAudioPermissionDenied() {
        // Show an alert explaining why we need audio and how to enable it
        let alert = UIAlertController(
            title: "Microphone Access Required",
            message: "This app needs microphone access for the check-in feature. Please enable it in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
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
        // Bring the timer label to the front so it's not obscured by other subviews
        view.bringSubviewToFront(timerLabel)
        
        view.addSubview(monitorAudioDataView)
        monitorAudioDataView.addSubview(audioVolumeView)
        
        NSLayoutConstraint.activate([
            monitorAudioDataView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            monitorAudioDataView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            monitorAudioDataView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            monitorAudioDataView.heightAnchor.constraint(equalTo: monitorAudioDataView.widthAnchor, multiplier: 0.5)
        ])
        
        // Ensure audioVolumeView is centered horizontally and vertically
        audioVolumeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            audioVolumeView.centerXAnchor.constraint(equalTo: monitorAudioDataView.centerXAnchor),
            audioVolumeView.centerYAnchor.constraint(equalTo: monitorAudioDataView.centerYAnchor)
        ])
        
        startSessionButton.addTarget(self, action: #selector(clickSessionButton(_:)), for: .touchUpInside)
        
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRealTimeStatusChanged(_:)),
            name: NSNotification.Name("RealTimeApiStatusChanged"),
            object: nil
        )
        
        startMonitoringUserAudio()
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
        if realTimeAPI.connect_status == "connected" {
            // Don't stop timer here anymore - only show the alert
            let alertVC = UIAlertController(
                title: "Are you sure you want to end the session?",
                message: "",
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let endSessionAction = UIAlertAction(title: "End Session", style: .default) { [weak self] alert in
                // Only stop timer and cleanup when user confirms
                self?.sessionTimer?.invalidate()
                self?.sessionTimer = nil
                self?.endSessionCleanupAndSummarize()
                // After ending a session, we force an update
                self?.updateCheckInButton()
            }
            alertVC.addAction(cancelAction)
            alertVC.addAction(endSessionAction)
            getCurrentVc().present(alertVC, animated: true)
            
        } else if realTimeAPI.connect_status == "connecting" {
            // Just refresh UI if user taps again
            updateCheckInButton()
        } else {
            // If not connected, start connecting
            realTimeAPI.connectWebSockt()
            // Immediately update the button to show "Connecting..."
            updateCheckInButton()
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
        // For an actual remote audio track, measure its volume similarly.
        // For now, do a placeholder animation:
        self.audioVolumeView.updateCircles(with: 0.8)
    }
    
    @objc func handleUserStartToSpeak() {
        // Possibly start local mic monitoring here too.
        self.audioVolumeView.updateCircles(with: 0.5)
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
            // Timer finished — do the same cleanup steps
            sessionTimer?.invalidate()
            sessionTimer = nil
            endSessionCleanupAndSummarize()
        }
    }

    // 1) Factor the common end-session logic into one helper method
    private func endSessionCleanupAndSummarize() {
        realTimeAPI.stopAll()
        realTimeAPI.connect_status = "notConnect"

        // Reset timer UI
        remainingTime = 120
        timerLabel.text = "2:00"
        
        // Save check-in without summary initially
        saveTodayCheckIn()
        
        // Update button state
        updateCheckInButton()

        // Stop visualizer
        audioVolumeView.resetCirclesForUserSpeaking()

        // Get conversation and summarize
        let conversation = realTimeAPI.conversationHistory.joined(separator: "\n")
        summarizeDailyConversation(conversation)
    }

    // Add a helper to send conversation off for summarizing
    private func summarizeDailyConversation(_ conversation: String) {
        // Remove placeholder text; pass in the actual conversation
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid URL")
            return
        }

        let messages: [[String: Any]] = [
            ["role": "user", "content": "Summarize the given conversation for key takeaways and important learnings to help the user remember what was talked about and what would be important for them to remember from the conversation to meet their goals. Summary should be roughly one paragraph. Refer to the user as you. Write from the perspective of the assistant with the same tone and temperament. \n\(conversation)"]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(openAiApiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
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

                        // Update today's check-in with the summary
                        self?.saveTodayCheckIn(summary: firstContent)

                        // 2) Store it in UserDefaults in "Stories" format
                        self?.storeSummarizedStory(firstContent)

                        // 2) After a successful session, store the lastCheckIn time
                        UserDefaults.standard.set(Date(), forKey: "lastCheckIn")
                        
                        // 3) Re-check the button state on the main thread
                        DispatchQueue.main.async {
                            self?.updateCheckInButton()
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
        // First check if user has already checked in today
        if hasCheckedInToday() {
            startSessionButton.isEnabled = false
            startSessionButton.backgroundColor = .lightGray
            startSessionButton.setTitle("Already checked in", for: .normal)
            return
        }
        
        // Otherwise, choose button state based on connection status
        switch realTimeAPI.connect_status {
        case "connecting":
            startSessionButton.isEnabled = false
            startSessionButton.backgroundColor = .lightGray
            startSessionButton.setTitle("Connecting...", for: .normal)
        case "connected":
            startSessionButton.isEnabled = true
            startSessionButton.backgroundColor = .systemRed
            startSessionButton.setTitle("End Session", for: .normal)
            if sessionTimer == nil {
                startTimer()
            }
        default: // "notConnect"
            startSessionButton.isEnabled = true
            startSessionButton.backgroundColor = GlobalColors.primaryButton
            startSessionButton.setTitle("Start Check-in", for: .normal)
        }
    }

    @objc private func handleRealTimeStatusChanged(_ notification: Notification) {
        // The RealTimeApiWebRTCMainVC has updated connect_status, so re-check button state:
        self.updateCheckInButton()
    }

    private func setupAudioLevelTimer() {
        // Invalidate existing timer if any
        self.audioLevelTimer?.invalidate()
        
        // Create new timer that fires 10 times per second
        self.audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let recorder = self.audioRecorder,
                  recorder.isRecording else { return }
            
            recorder.updateMeters()
            var scale = 0.0

            // Only compute actual volume if session is active
            if self.realTimeAPI.connect_status == "connected" {
                let avgPower = recorder.averagePower(forChannel: 0)
                if avgPower <= -60 {
                    scale = 0.0
                } else if avgPower >= -5 {
                    scale = 1.0
                } else {
                    scale = Double((avgPower + 60) * 1.5 / 100.0)
                    // Low pass filter
                    if scale < 0.3 { scale = 0.0 }
                }
            }
            
            // If not connected, scale remains 0
            
            DispatchQueue.main.async {
                self.audioVolumeView.updateCircles(with: Float(scale))
            }
        }
        
        // Make sure timer runs even during scrolling
        RunLoop.current.add(self.audioLevelTimer!, forMode: .common)
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

