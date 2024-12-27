import UIKit

class PaddingTextField: UITextField {
    let padding = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

class OnboardingViewController: UIViewController {

    private var currentStep = 1
    private let totalSteps = 5

    // 1) Add array to store text responses for each step
    private var responses = Array(repeating: "", count: 5)

    // An array of step-specific questions
    private let stepPrompts = [
        "Which goal or habit do you most want to focus on right now?",
        "What usually stops you from following through on this goal?",
        "How would you like the app to respond when you’re struggling?",
        "When and how often would you like check-in(s)?",
        "Imagine you’re looking back 30 days from now—how will you know you’ve made real progress?"
    ]

    // 2) Add a new title label (smaller and left-aligned)
    private lazy var stepTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .left
        label.text = stepPrompts[currentStep - 1]
        // 1) Enable wrapping and multiple lines
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = GlobalColors.primaryText
        return label
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        button.tintColor = GlobalColors.primaryButton
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        return button
    }()

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = GlobalColors.primaryButton
        progress.trackTintColor = .lightGray
        return progress
    }()

    private lazy var textField: PaddingTextField = {
        let tf = PaddingTextField()
        tf.borderStyle = .roundedRect
        // 2) Slightly lighter border
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8
        tf.layer.masksToBounds = true
        
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textAlignment = .left
        tf.contentVerticalAlignment = .top
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = GlobalColors.accentBackground
        tf.textColor = GlobalColors.primaryText
        return tf
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        button.backgroundColor = GlobalColors.primaryButton
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = GlobalColors.mainBackground

        // 4) Add subviews
        view.addSubview(backButton)
        view.addSubview(progressView)
        view.addSubview(stepTitleLabel)
        view.addSubview(textField)
        view.addSubview(nextButton)

        // Layout using Auto Layout
        backButton.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),

            progressView.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            // 3) Title label now has trailing anchor for wrapping
            stepTitleLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            stepTitleLabel.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            stepTitleLabel.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -16),

            // 4) Make the text field wider and taller
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            textField.heightAnchor.constraint(equalToConstant: 100),

            // 5) Center the “Next” button to match text field’s width
            nextButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 16),
            nextButton.centerXAnchor.constraint(equalTo: textField.centerXAnchor),
            nextButton.widthAnchor.constraint(equalTo: textField.widthAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 60),
        ])

        // Initial update
        updateProgressBar()
    }

    private func updateProgressBar() {
        // Fill progress based on the current step
        let progressFraction = Float(currentStep) / Float(totalSteps)
        progressView.setProgress(progressFraction, animated: true)

        // 7) Use the array of prompts
        stepTitleLabel.text = stepPrompts[currentStep - 1]
        textField.text = responses[currentStep - 1]

        // Hide back button if on first step
        backButton.isHidden = (currentStep == 1)
    }

    @objc private func handleBack() {
        // 8) Save current text before going back
        responses[currentStep - 1] = textField.text ?? ""
        guard currentStep > 1 else { return }
        currentStep -= 1
        updateProgressBar()
    }

    @objc private func handleNext() {
        responses[currentStep - 1] = textField.text ?? ""
        guard currentStep < totalSteps else {
            let upsellVC = UpsellViewController()
            upsellVC.modalPresentationStyle = .fullScreen

            upsellVC.userResponses = responses

            present(upsellVC, animated: true)
            return
        }
        currentStep += 1
        updateProgressBar()
    }

    // 5) Remove observer when done
    deinit {
        // No need to remove observer when done
    }
} 
