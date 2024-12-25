import UIKit

class ProgressViewController: UIViewController {
    
    // Instead of a single table, create a horizontally-paging scrollView
    private let scrollView = UIScrollView()
    
    // Three table views (one per tab)
    private let daysTableView = UITableView(frame: .zero, style: .grouped)
    private let weeksTableView = UITableView(frame: .zero, style: .grouped)
    private let monthsTableView = UITableView(frame: .zero, style: .grouped)
    
    // Data for each tab
    private let dayTitles = [
        "Today, December 24th 2024",
        "Yesterday, December 23rd 2024",
        "Sunday, December 22nd 2024",
        "Saturday, December 21st 2024"
    ]
    private let weeksTitles = ["Week 1, 2024", "Week 2, 2024", "Week 3, 2024"]
    private let monthsTitles = ["December, 2024", "November, 2024", "October, 2024"]
    
    // A segmented control for switching between Days, Weeks, and Months
    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Days", "Weeks", "Months"])
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(handleSegmentChange(_:)), for: .valueChanged)
        return sc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up everything
        setupViews()
        setupScrollView()
        setupTables()
    }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Create a container for the label + tab control
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Your Story"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(segmentedControl)
        
        // Constraints for container, label, segmented control
        NSLayoutConstraint.activate([
            // Pin container to safe area top, left, right
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            segmentedControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        // Position the scrollView below that container, pinned to bottom
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        // Enable paging + hide horizontal scrollbar for a smooth “pages” feel
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        // Observe scrollView events so we can update the segmentedControl when user swipes
        scrollView.delegate = self
    }
    
    private func setupTables() {
        // The scrollView width is unknown until layout, but we can do what we can here
        // We’ll also set frames in viewDidLayoutSubviews to ensure correct final sizing
        
        // Register basic cells
        daysTableView.register(UITableViewCell.self, forCellReuseIdentifier: "DaysCell")
        weeksTableView.register(UITableViewCell.self, forCellReuseIdentifier: "WeeksCell")
        monthsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MonthsCell")
        
        // Assign delegates
        daysTableView.dataSource = self
        weeksTableView.dataSource = self
        monthsTableView.dataSource = self
        
        // Add subviews
        scrollView.addSubview(daysTableView)
        scrollView.addSubview(weeksTableView)
        scrollView.addSubview(monthsTableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Each table view’s frame is the entire size of the scrollView
        let width = scrollView.bounds.width
        let height = scrollView.bounds.height
        
        daysTableView.frame   = CGRect(x: 0 * width, y: 0, width: width, height: height)
        weeksTableView.frame  = CGRect(x: 1 * width, y: 0, width: width, height: height)
        monthsTableView.frame = CGRect(x: 2 * width, y: 0, width: width, height: height)
        
        // Set content size to hold all 3 “pages”
        scrollView.contentSize = CGSize(width: 3 * width, height: height)
    }
    
    @objc private func handleSegmentChange(_ sender: UISegmentedControl) {
        // Animate the scroll to the chosen page
        let pageIndex = sender.selectedSegmentIndex
        let offsetX = CGFloat(pageIndex) * scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ProgressViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // When user finishes manual swipe, update segmented control
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        segmentedControl.selectedSegmentIndex = pageIndex
    }
}

// MARK: - UITableViewDataSource for each table
extension ProgressViewController: UITableViewDataSource, UITableViewDelegate {
    // 1) Sections correspond to days/weeks/months, so return their counts
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == daysTableView {
            return dayTitles.count
        } else if tableView == weeksTableView {
            return weeksTitles.count
        } else { // monthsTableView
            return monthsTitles.count
        }
    }
    
    // 2) Use the corresponding array string as the section header text
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == daysTableView {
            return dayTitles[section]
        } else if tableView == weeksTableView {
            return weeksTitles[section]
        } else {
            return monthsTitles[section]
        }
    }
    
    // 3) Each section has one row
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // 4) Return a cell with multiline text
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Reuse whichever cell type suits. Here, we’ll show a dummy multiline text
        let reuseIdentifier: String
        switch tableView {
        case daysTableView:   reuseIdentifier = "DaysCell"
        case weeksTableView:  reuseIdentifier = "WeeksCell"
        default:              reuseIdentifier = "MonthsCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = """
        This is example text for the body of each section. 
        Replace it with whatever text or controls you need. 
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
        """
        return cell
    }
}
