import UIKit

class RootViewController: UIViewController {

    lazy var audioVolumeView = {
        let view = AudioVisualizerView(frame: CGRect(x: UIScreen.main.bounds.size.width/2-200/2, y: 30, width: 200, height: 100))

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GlobalColors.mainBackground
        
        view.addSubview(startSessionButton)
        view.addSubview(monitorAudioDataView)
        
        monitorAudioDataView.addSubview(audioVolumeView)
        
        startSessionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        startSessionButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        startSessionButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        startSessionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        monitorAudioDataView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
        monitorAudioDataView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        monitorAudioDataView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        monitorAudioDataView.heightAnchor.constraint(equalToConstant: 190).isActive = true
        
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
        
        let habitsLabel = UILabel()
        habitsLabel.text = "Habits"
        habitsLabel.font = UIFont.boldSystemFont(ofSize: 20)
        habitsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(habitsLabel)
        
        NSLayoutConstraint.activate([
            habitsLabel.topAnchor.constraint(equalTo: startSessionButton.bottomAnchor, constant: 20),
            habitsLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            habitsLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        habitsLabel.textColor = GlobalColors.primaryText
        
        view.addSubview(partialBlurTableView)
        partialBlurTableView.delegate = self
        partialBlurTableView.dataSource = self
        NSLayoutConstraint.activate([
            partialBlurTableView.topAnchor.constraint(equalTo: habitsLabel.bottomAnchor, constant: 8),
            partialBlurTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            partialBlurTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            partialBlurTableView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        partialBlurTableView.backgroundColor = GlobalColors.mainBackground
        
        view.addSubview(bottomBlurView)
        NSLayoutConstraint.activate([
            bottomBlurView.leadingAnchor.constraint(equalTo: partialBlurTableView.leadingAnchor),
            bottomBlurView.trailingAnchor.constraint(equalTo: partialBlurTableView.trailingAnchor),
            bottomBlurView.bottomAnchor.constraint(equalTo: partialBlurTableView.bottomAnchor),
            bottomBlurView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        partialBlurTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 25, right: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bottomBlurView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let gradient = CAGradientLayer()
        gradient.frame = bottomBlurView.bounds
        
        gradient.colors = [
            UIColor.systemBackground.withAlphaComponent(0.2).cgColor,
            UIColor.systemBackground.withAlphaComponent(1.0).cgColor
        ]
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1.0)
        bottomBlurView.layer.addSublayer(gradient)
    }
    
    @objc func clickSessionButton(_ sender: Any) {
        if WebSocketManager.shared.connected_status == "connected" {
            let alertVC = UIAlertController(title: "The websocket is connected. Disconnect?", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let confirAction = UIAlertAction(title: "Confirm", style: .default) { alert in
                WebSocketManager.shared.audio_String = ""
                WebSocketManager.shared.audio_String_count = 0
                PlayAudioCotinuouslyManager.shared.audio_event_Queue.removeAll()
                RecordAudioManager.shared.pauseCaptureAudio()
                WebSocketManager.shared.socket.disconnect()
            }
            alertVC.addAction(cancelAction)
            alertVC.addAction(confirAction)
            getCurrentVc().present(alertVC, animated: true)
        } else {
            WebSocketManager.shared.connectWebSocketOfOpenAi()
        }
    }
    
    @objc func openAiStatusChanged(){
        if WebSocketManager.shared.connected_status == "not_connected" {
            startSessionButton.setTitle("Start Check-in", for: .normal)
        } else if WebSocketManager.shared.connected_status == "connecting" {
            startSessionButton.setTitle("Connecting...", for: .normal)
        } else if WebSocketManager.shared.connected_status == "connected" {
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

