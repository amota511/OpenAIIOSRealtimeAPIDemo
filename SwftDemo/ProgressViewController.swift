import UIKit

class ProgressViewController: UIViewController,
                             UITableViewDataSource,
                             UITableViewDelegate
{
    // Create a single table
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    // Keep the dayTitles or rename as needed
    private let dayTitles = [
        "Today, December 24th 2024",
        "Yesterday, December 23rd 2024",
        "Sunday, December 22nd 2024",
        "Saturday, December 21st 2024"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        setupViews()
        setupTable()
        
        view.backgroundColor = GlobalColors.mainBackground
    }
    
    private func setupViews() {
        view.backgroundColor = GlobalColors.mainBackground
        
        // Create a container for the label
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Your Story"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = GlobalColors.primaryText
        containerView.addSubview(titleLabel)
        
        // Constraints for container, label
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        // Position the single table below that container
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTable() {
        // Register cells and assign self as dataSource & delegate
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.backgroundColor = GlobalColors.mainBackground
        tableView.allowsSelection = false
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dayTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dayTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = """
        This is example text for the body of each section.
        Replace it with whatever text or controls you need.
        """
        cell.backgroundColor = GlobalColors.mainBackground
        cell.textLabel?.textColor = GlobalColors.primaryText
        return cell
    }
}
