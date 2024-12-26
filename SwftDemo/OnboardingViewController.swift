import UIKit
import StoreKit

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

class OnboardingViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    private var currentStep = 1
    private let totalSteps = 5

    // 1) Add array to store text responses for each step
    private var responses = Array(repeating: "", count: 5)

    // Subscription product
    private var subscriptionProduct: SKProduct?
    private let productIdentifiers: Set<String> = ["monthly_20_v1"]

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
        return label
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        return button
    }()

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemBlue
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

        // 3) Set up payment queue observer
        SKPaymentQueue.default().add(self)

        // 4) Fetch the product from the App Store
        fetchSubscriptionProduct()

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

            // Keep “Next” button near the bottom-right of text field
            nextButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
        ])

        // Initial update
        updateProgressBar()
    }

    // MARK: - Fetch subscription product
    private func fetchSubscriptionProduct() {
        guard SKPaymentQueue.canMakePayments() else {
            print("User cannot make payments.")
            return
        }
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // If there's a matching product, store a reference to it
        if let product = response.products.first {
            subscriptionProduct = product
            print("Fetched product: \(product.localizedTitle) - \(product.price)")
        } else {
            print("No products found.")
        }
    }

    // Handle errors
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Product request error: \(error.localizedDescription)")
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
            // Present the UpsellViewController modally
            let upsellVC = UpsellViewController()
            upsellVC.modalPresentationStyle = .fullScreen
            present(upsellVC, animated: true)
            return
        }
        currentStep += 1
        updateProgressBar()
    }

    // MARK: - Purchase flow
    private func purchaseSubscription() {
        guard let product = subscriptionProduct else {
            // We haven't successfully fetched the product or there's no product to buy
            print("Subscription product not available.")
            return
        }
        // Begin the official payment
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    // MARK: - Transaction Observer
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Payment was successful. Finish and show main tab bar
                SKPaymentQueue.default().finishTransaction(transaction)
                showMainTabBar()
            case .restored:
                // If you have a "Restore Purchases" flow
                SKPaymentQueue.default().finishTransaction(transaction)
                showMainTabBar()
            case .failed:
                // Payment was canceled or failed
                SKPaymentQueue.default().finishTransaction(transaction)
            case .purchasing, .deferred:
                // We can ignore these states, or handle them as needed
                break
            @unknown default:
                break
            }
        }
    }

    // MARK: - Show main UI
    private func showMainTabBar() {
        let mainTabBarController = MainTabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainTabBarController
            window.makeKeyAndVisible()
        }
    }

    // 5) Remove observer when done
    deinit {
        SKPaymentQueue.default().remove(self)
    }
} 
