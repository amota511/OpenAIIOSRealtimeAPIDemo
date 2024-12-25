import UIKit

class ProgressViewController: UIViewController {
    
    // 1) Add a tableView property and a simple model for multiple days
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let dayTitles = ["Today, December 24th 2024", "Yesterday, December 23rd 2024", "Sunday, December 22nd 2024", "Saturday, December 21st 2024"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 2) Configure and add the table view
        setupTableView()
    }
    
    // 3) Create a function to set up the table view and header
    private func setupTableView() {
        // Add tableView to the view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set large header for the entire table
        let headerLabel = UILabel()
        headerLabel.text = "Your Story"
        headerLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        headerLabel.frame.size.height = 100
        tableView.tableHeaderView = headerLabel
        
        // Register default cell types (for demonstration)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TextViewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        
        // Assign dataSource & delegate
        tableView.dataSource = self
        tableView.delegate = self
    }
}
// 4) Conform to UITableViewDataSource & UITableViewDelegate
extension ProgressViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dayTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dayTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = """
                This is some example text spanning a few lines to illustrate the text view.
                Feel free to replace it with real content.
                Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
                """
            return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
        
}
