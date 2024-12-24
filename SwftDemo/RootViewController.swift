import UIKit

class RootViewController: UIViewController {

    lazy var audioVolumeView = {
        let view = AudioVisualizerView(frame: CGRect(x: UIScreen.main.bounds.size.width/2-200/2, y: 30, width: 200, height: 100))
        return view
    }()
    
    let startSessionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Click to Connect OpenAI", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let discconnectAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Disconnect Open AI", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let inputTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .systemGray5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    let outputTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .systemGray5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    let monitorAudioDataView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let inputLabel: UILabel = {
        let label = UILabel()
        label.text = "What I am talking"
        label.font = UIFont.systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let outputLabel: UILabel = {
        let label = UILabel()
        label.text = "OpenAI response"
        label.font = UIFont.systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(discconnectAIButton)
        view.addSubview(startSessionButton)
        view.addSubview(monitorAudioDataView)
        view.addSubview(inputLabel)
        view.addSubview(inputTextView)
        view.addSubview(outputLabel)
        view.addSubview(outputTextView)
        
        monitorAudioDataView.addSubview(audioVolumeView)
        
        discconnectAIButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        discconnectAIButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30).isActive = true
        discconnectAIButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        discconnectAIButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        
        startSessionButton.topAnchor.constraint(equalTo: discconnectAIButton.bottomAnchor, constant: 20).isActive = true
        startSessionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30).isActive = true
        startSessionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30).isActive = true
        startSessionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        monitorAudioDataView.topAnchor.constraint(equalTo: startSessionButton.bottomAnchor, constant: 20).isActive = true
        monitorAudioDataView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        monitorAudioDataView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        monitorAudioDataView.heightAnchor.constraint(equalToConstant: 190).isActive = true
        
        inputLabel.topAnchor.constraint(equalTo: monitorAudioDataView.bottomAnchor, constant: 20).isActive = true
        inputLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25).isActive = true
        
        inputTextView.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: 15).isActive = true
        inputTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25).isActive = true
        inputTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25).isActive = true
        inputTextView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        outputLabel.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 50).isActive = true
        outputLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25).isActive = true
        
        outputTextView.topAnchor.constraint(equalTo: outputLabel.bottomAnchor, constant: 15).isActive = true
        outputTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25).isActive = true
        outputTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25).isActive = true
        outputTextView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        outputTextView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25).isActive = true
        
        startSessionButton.addTarget(self, action: #selector(clickStartSessionButton(_:)), for: .touchUpInside)
        discconnectAIButton.addTarget(self, action: #selector(clickDisConnecteButton(_:)), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(openAiStatusChanged), name: NSNotification.Name(rawValue: "WebSocketManager_connected_status_changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserStartToSpeek), name: NSNotification.Name(rawValue: "UserStartToSpeek"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HaveInputText(notifiction:)), name: NSNotification.Name(rawValue: "HaveInputText"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HaveOutputText(notifiction:)), name: NSNotification.Name(rawValue: "HaveOutputText"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showMonitorAudioDataView(notification:)), name: NSNotification.Name(rawValue: "showMonitorAudioDataView"), object: nil)
    }
    
    @objc func clickStartSessionButton(_ sender: Any) {
        WebSocketManager.shared.connectWebSocketOfOpenAi()
    }
    
    @objc func openAiStatusChanged(){
        if WebSocketManager.shared.connected_status == "not_connected"{
            startSessionButton.setTitle("Open AI: not_connected", for: .normal)
            discconnectAIButton.isHidden = true
        }else
        if WebSocketManager.shared.connected_status == "connecting"{
            startSessionButton.setTitle("Open AI: connecting", for: .normal)
            discconnectAIButton.isHidden = true
        }else
        if WebSocketManager.shared.connected_status == "connected"{
            startSessionButton.setTitle("Open AI: connected", for: .normal)
            discconnectAIButton.isHidden = false
        }else{
            startSessionButton.setTitle("", for: .normal)
            discconnectAIButton.isHidden = true
        }
    }
    
    @objc func clickDisConnecteButton(_ sender: Any) {
        let alertVC = UIAlertController(title: "The websocket is connected, So do you want to disconnect it? ", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let confirAction = UIAlertAction(title: "Confirm", style: .default) { alert in
            //stop play audio
            WebSocketManager.shared.audio_String = ""
            WebSocketManager.shared.audio_String_count = 0
            PlayAudioCotinuouslyManager.shared.audio_event_Queue.removeAll()
            //pause captrue audio
            RecordAudioManager.shared.pauseCaptureAudio()
            //Disconnect websockt--It will recieve .peerClosed and cancelled
            WebSocketManager.shared.socket.disconnect()
        }
        alertVC.addAction(cancelAction)
        alertVC.addAction(confirAction)
        getCurrentVc().present(alertVC, animated: true)
    }
    
    @objc func UserStartToSpeek(){
        self.inputTextView.text = ""
        self.outputTextView.text = ""
    }
    
    @objc func HaveInputText(notifiction: Notification){
        if let dict = notifiction.object as? [String: Any] {
            if let transcript = dict["text"] as? String{
                self.inputTextView.text = transcript
            }
        }
    }
    
    @objc func HaveOutputText(notifiction: Notification){
        if let dict = notifiction.object as? [String: String] {
            if let transcript = dict["text"] as? String {
                self.outputTextView.text = transcript
            }
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
    
}

