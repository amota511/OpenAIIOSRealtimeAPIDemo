import UIKit
import StoreKit

class UpsellViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    private let productIdentifiers: Set<String> = ["monthly_20_v1"]
    private var subscriptionProduct: SKProduct?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "We want you to try Reason.ai for free."
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "upsell-image-3")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var checkMarkLabel: UILabel = {
        let label = UILabel()
        // Using an SF Symbol for a checkmark:
        // “checkmark.circle.fill” or “checkmark.seal.fill,” etc.
        label.text = "✓ No payment due now"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Try for $0.00", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleTrial), for: .touchUpInside)
        return button
    }()
    
    private lazy var priceDetailsLabel: UILabel = {
        let label = UILabel()
        label.text = "Just $0.66 per day (19.99/mo)"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(imageView)
        view.addSubview(checkMarkLabel)
        view.addSubview(tryButton)
        view.addSubview(priceDetailsLabel)
        
        // Register self as a payment queue observer
        SKPaymentQueue.default().add(self)
        
        // Fetch product from the App Store
        fetchSubscriptionProduct()
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title at the top
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Image below title, 60% height
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // Check mark label below image
            checkMarkLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            checkMarkLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            checkMarkLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // “Try” button below check mark
            tryButton.topAnchor.constraint(equalTo: checkMarkLabel.bottomAnchor, constant: 24),
            tryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tryButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            tryButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Small price label below the button
            priceDetailsLabel.topAnchor.constraint(equalTo: tryButton.bottomAnchor, constant: 8),
            priceDetailsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            priceDetailsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
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
        if let product = response.products.first {
            subscriptionProduct = product
            print("Fetched product: \(product.localizedTitle) - \(product.price)")
        } else {
            print("No products found.")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Product request error: \(error.localizedDescription)")
    }
    
    @objc private func handleTrial() {
        // For demonstration, start payment flow instead of dismissing
        purchaseSubscription()
    }
    
    // MARK: - Purchase flow
    private func purchaseSubscription() {
        guard let product = subscriptionProduct else {
            print("Subscription product not available.")
            showMainTabBar()
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Transaction Observer
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                showMainTabBar()
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                showMainTabBar()
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func showMainTabBar() {
        let mainTabBarController = MainTabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainTabBarController
            window.makeKeyAndVisible()
        }
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
} 
