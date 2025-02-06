import UIKit

enum LegalDocumentType {
    case terms
    case privacy
    
    var title: String {
        switch self {
        case .terms:
            return "Terms and Conditions"
        case .privacy:
            return "Privacy Policy"
        }
    }
    
    var content: String {
        switch self {
        case .terms:
            return LegalViewController.termsText
        case .privacy:
            return LegalViewController.privacyText
        }
    }
}

class LegalViewController: UIViewController {
    private let documentType: LegalDocumentType
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = documentType.content
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(type: LegalDocumentType) {
        self.documentType = type
        super.init(nibName: nil, bundle: nil)
        self.title = type.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupScrollView()
    }
    
    private func setupScrollView() {
        view.addSubview(dismissButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            // Dismiss button constraints
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView constraints (scroll content container)
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Content label constraints
            contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    static let termsText = """
    Terms and Conditions for Reason.ai
    
    Last Updated: February 6, 2025
    
    Welcome to Reason.ai (“App”), an iOS application provided by Kalaida Studios (“Company,” “we,” “us,” or “our”). By downloading, installing, or using the App, you agree to these Terms and Conditions (“Terms”). If you do not agree to these Terms, please do not use the App.
    
    1. Acceptance of Terms
    By accessing or using the App, you represent and warrant that you are at least 18 years of age and have the legal capacity to enter into these Terms. Your use of the App is conditioned upon your acceptance of these Terms, which form a legally binding agreement between you and Kalaida Studios.
    
    2. License and Use
    2.1. License Grant.
    Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to download and use the App solely for your personal, non-commercial use on any iOS device that you own or control.
    
    2.2. Restrictions.
    You agree not to:
    
    Modify, adapt, or create derivative works based on the App.
    Reverse engineer, decompile, or disassemble the App.
    Use the App for any unlawful purpose or in any manner that could damage, disable, overburden, or impair the App or interfere with any other party’s use of the App.
    Attempt to gain unauthorized access to any part of the App or its underlying systems.
    3. Modification of Terms
    Kalaida Studios reserves the right, in our sole discretion, to modify, suspend, or discontinue these Terms—or any portion of the App—at any time without notice. Your continued use of the App after any changes constitutes your acceptance of the modified Terms.
    
    4. Termination and Revocation of Access
    We reserve the right, at our sole discretion and without prior notice, to suspend or terminate your access to the App at any time and for any reason, including, but not limited to, any violation of these Terms. Upon termination, your right to use the App will immediately cease.
    
    5. Disclaimers and No Liability for Misuse
    5.1. “As Is” Basis.
    The App is provided on an “as is” and “as available” basis without any warranties of any kind, either express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, or non-infringement.
    
    5.2. No Liability.
    To the fullest extent permitted by applicable law, in no event shall Kalaida Studios, its affiliates, or their respective officers, directors, employees, or agents be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, arising from your access to, or use of, the App—even if advised of the possibility of such damages.
    
    5.3. No Legal Fault.
    Kalaida Studios shall not be held legally responsible for any misuse of the App or for any consequences arising from your reliance on the App’s content or functionality. Use of the App is entirely at your own risk.
    
    6. Indemnification
    You agree to indemnify, defend, and hold harmless Kalaida Studios and its affiliates, officers, directors, employees, and agents from and against any and all claims, liabilities, damages, losses, or expenses (including reasonable attorneys’ fees and costs) arising out of or in any way connected with your access to or use of the App, your violation of these Terms, or your infringement of any intellectual property or other rights of any person or entity.
    
    7. Intellectual Property
    All content, features, and functionality of the App—including, but not limited to, all information, software, text, displays, images, video, and audio, and the design, selection, and arrangement thereof—are owned by Kalaida Studios or its licensors and are protected by applicable intellectual property laws. You agree not to copy, modify, distribute, sell, or lease any part of our intellectual property without our prior written consent.
    
    8. Governing Law and Dispute Resolution
    These Terms shall be governed by and construed in accordance with the laws of [Your Jurisdiction] without regard to its conflict of law principles. Any disputes arising out of or relating to these Terms or the App shall be resolved exclusively in the state or federal courts located within [Your Jurisdiction], and you consent to the personal jurisdiction and venue of these courts.
    
    9. Severability
    If any provision of these Terms is found to be invalid or unenforceable by a court of competent jurisdiction, such provision shall be deemed severed from these Terms and the remaining provisions shall remain in full force and effect.
    
    10. Entire Agreement
    These Terms, together with any other legal notices or agreements published by us on the App, constitute the entire agreement between you and Kalaida Studios regarding your use of the App and supersede all prior and contemporaneous understandings, agreements, representations, and warranties, both written and oral.
    
    11. Third-Party Services and Use of OpenAI’s Real-Time API
    Reason.ai utilizes OpenAI’s real-time API to deliver interactive, AI-driven features as part of the App’s services. By using the App, you acknowledge and agree that:
    
    Your interactions may involve the processing of data by OpenAI.
    OpenAI’s services are subject to its own terms and conditions, which you should review.
    Kalaida Studios does not control the processing of your data by OpenAI and is not responsible for any issues arising from or related to the use of OpenAI’s API.
    You agree to comply with any additional terms imposed by OpenAI in connection with its API usage.
    12. Contact Information
    If you have any questions, concerns, or comments regarding these Terms or the App, please contact us at:
    
    Kalaida Studios
    reason.habitbuilder.gmail.com
    
    By using the App, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.
    """
    
    static let privacyText = """
    Privacy Policy for Reason.ai
    
    Effective Date: February 6, 2025
    
    At Kalaida Studios, your privacy is a top priority. This Privacy Policy explains what data we collect, how we use it, and the measures we take to protect your information when you use our iOS application, Reason.ai.
    
    1. Information We Collect
    1.1. Personal Information
    We may collect personal data that you voluntarily provide when using the App, such as your name, email address, or any other information you choose to share.
    
    1.2. Usage Data
    The App automatically collects non-personal information to help us understand how you use Reason.ai. This may include details such as device type, operating system, IP address, app interactions, and crash logs.
    
    1.3. Third-Party Data
    Reason.ai uses OpenAI’s real-time API to deliver interactive, AI-driven features. When you interact with the App, some data may be processed by OpenAI. Please note that OpenAI’s data handling is governed by its own privacy practices and policies.
    
    2. How We Use Your Information
    To Provide and Improve Our Services:
    We use your data to operate, personalize, and enhance the functionality of Reason.ai.
    To Communicate with You:
    Your contact details may be used to send you updates, support messages, or other communications related to your use of the App.
    For Analytics and Monitoring:
    Usage data helps us understand user behavior, troubleshoot issues, and continuously improve the overall experience.
    3. Sharing Your Information
    With Third Parties:
    We do not sell or rent your personal information. We may share your data with trusted partners who assist in delivering our services—under strict confidentiality agreements. This includes sharing data processed via OpenAI’s API, which is subject to OpenAI’s own policies.
    For Legal Purposes:
    We may disclose your information if required by law, or if we believe such disclosure is necessary to comply with legal obligations, protect our rights, or ensure the safety of our users.
    4. Data Retention
    We will retain your personal information only as long as necessary to fulfill the purposes for which it was collected, or as required by applicable law. Once the data is no longer needed, we will take steps to securely delete or anonymize it.
    
    5. Data Security
    Kalaida Studios implements industry-standard security measures to safeguard your personal data against unauthorized access, alteration, disclosure, or destruction. While we strive to protect your information, no system is completely foolproof, and we cannot guarantee absolute security.
    
    6. Children's Privacy
    Reason.ai is not intended for use by children under the age of 13. We do not knowingly collect personal data from children. If we discover that personal data from a child under 13 has been collected, we will promptly delete such data.
    
    7. Your Rights and Choices
    Depending on your jurisdiction, you may have rights regarding your personal data, including the right to access, correct, or delete your information. If you have any questions or wish to exercise your rights, please contact us using the details provided below.
    
    8. Changes to This Privacy Policy
    We may update this Privacy Policy periodically. Any changes will be posted on this page along with an updated effective date. Your continued use of Reason.ai after any changes are posted constitutes your acceptance of such updates.
    
    9. Contact Us
    If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please reach out to us at:
    
    Kalaida Studios
    reason.habitbuilder.gmail.com
    
    By using Reason.ai, you acknowledge that you have read and understand this Privacy Policy and agree to its terms.
    """
} 
