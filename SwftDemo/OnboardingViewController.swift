import UIKit

class OnboardingViewController: UIViewController {

    private var currentStep = 1
    private let totalSteps = 5

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back", for: .normal)
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = .lightGray
        return progress
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "Enter step \(currentStep) info..."
        return tf
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Add subviews
        view.addSubview(backButton)
        view.addSubview(progressView)
        view.addSubview(textField)
        view.addSubview(nextButton)

        // Layout using Auto Layout
        backButton.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),

            progressView.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            textField.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 40),
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            nextButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 0),
        ])

        // Initial setup
        updateProgressBar()
    }

    private func updateProgressBar() {
        // Fill progress based on the current step (e.g., step 3 → 3/5 = 0.6)
        let progressFraction = Float(currentStep) / Float(totalSteps)
        progressView.setProgress(progressFraction, animated: true)
        textField.placeholder = "Enter step \(currentStep) info..."
        
        // Hide the back button on the first step
        backButton.isHidden = (currentStep == 1)
    }

    @objc private func handleBack() {
        // Decrement step if possible
        guard currentStep > 1 else { return }
        currentStep -= 1
        updateProgressBar()
    }

    @objc private func handleNext() {
        guard currentStep < totalSteps else {
            let mainTabBarController = MainTabBarController()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = mainTabBarController
                window.makeKeyAndVisible()
            }
            return
        }
        currentStep += 1
        updateProgressBar()
    }
} 