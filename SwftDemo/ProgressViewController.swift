import UIKit

class ProgressViewController: UIViewController,
                             UITableViewDataSource,
                             UITableViewDelegate
{
    // Create a single table
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    // 1) Define the StoryItem struct
    private struct StoryItem: Codable {
        let date: String
        let story: String
    }
    
    // 2) Replace the old dayTitles array with a new stories array
    private var stories = [StoryItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        // Load array from UserDefaults under key "Stories"
        loadStoriesFromUserDefaults()
        
        setupViews()
        setupTable()
        view.backgroundColor = GlobalColors.mainBackground
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Each time the user re-enters this view, reload stories
        loadStoriesFromUserDefaults()
    }
    
    // 3) Decode from UserDefaults and reload table
    private func loadStoriesFromUserDefaults() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "Stories") else {
            print("No stories found in UserDefaults.")
            return
        }
        do {
            let decoded = try JSONDecoder().decode([StoryItem].self, from: data)
            stories = decoded
            tableView.reloadData()
        } catch {
            print("Failed to decode stories: \(error)")
        }
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

        // 1) Add a UIRefreshControl for pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // 2) Called when user pulls to refresh
    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        loadStoriesFromUserDefaults()
        sender.endRefreshing()
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return stories.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Use the date field as the section header
        return stories[section].date
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        
        // Use the story field as the cell text
        cell.textLabel?.text = stories[indexPath.section].story

        cell.backgroundColor = GlobalColors.mainBackground
        cell.textLabel?.textColor = GlobalColors.primaryText
        return cell
    }
}
