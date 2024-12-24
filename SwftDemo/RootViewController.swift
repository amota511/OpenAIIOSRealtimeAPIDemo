import UIKit

class RootViewController: UIViewController {

    lazy var audioVolumeView = {
        let view = AudioVisualizerView(frame: CGRect(x: UIScreen.main.bounds.size.width/2-200/2, y: 30, width: 200, height: 100))
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        return view
    }()
    
    let startSessionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("begin check-in", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let monitorAudioDataView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
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
            startSessionButton.setTitle("begin check-in", for: .normal)
        } else if WebSocketManager.shared.connected_status == "connecting" {
            startSessionButton.setTitle("connecting...", for: .normal)
        } else if WebSocketManager.shared.connected_status == "connected" {
            startSessionButton.setTitle("End check-in", for: .normal)
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

