import UIKit

class TalkThroughViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Sticky header label
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Talk through"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 1) Add a new subHeaderLabel:
    private let subHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Talk though your sticking points with an expert level Ai"
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // A vertical list using UITableView
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let howTos = ["Drinking More Water",
    "Getting To Bed On Time", "Staying asleep", "Exercising More", "Going to the gym", "Eating Healthier", "Losing weight", "Keeping weight off"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = GlobalColors.mainBackground
        
        // Add the label as a subview (sticky header)
        view.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // 2) Add subHeaderLabel beneath headerLabel:
        view.addSubview(subHeaderLabel)
        NSLayoutConstraint.activate([
            subHeaderLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            subHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Set up the tableView below the label
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: subHeaderLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // headerLabel
        headerLabel.textColor = GlobalColors.primaryText
        
        // subHeaderLabel for details
        subHeaderLabel.textColor = GlobalColors.secondaryText
        
        tableView.backgroundColor = GlobalColors.mainBackground
        
        tableView.allowsSelection = false
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Example row count
        return howTos.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "cellId"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
            ?? UITableViewCell(style: .default, reuseIdentifier: cellId)
        cell.textLabel?.text = howTos[indexPath.row]
        cell.backgroundColor = GlobalColors.mainBackground
        cell.textLabel?.textColor = GlobalColors.primaryText
        return cell
    }
    
    // MARK: - UITableViewDelegate
    // (Optional: implement methods for handling row selection, etc.)
} 
