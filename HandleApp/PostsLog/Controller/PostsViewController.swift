//
//  PostsViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//

import UIKit

class PostsViewController: UIViewController {

    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var weekDayStackView: UIStackView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var publishedButton: UIButton!
    @IBOutlet weak var scheduledButton: UIButton!
    @IBOutlet weak var savedButton: UIButton!
    @IBOutlet weak var postsTableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    var currentWeekStartDate: Date = Calendar.current.startOfDay(for: Date())
    var todayScheduledPosts: [Post] = {
        do {
            return try Post.loadTodayScheduledPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load scheduled posts. Details: \(error)")
            return []
        }
    }()
    
    @IBAction func nextTapped(_ sender: Any) {
        scrollWeek(by: 7)
    }
    @IBAction func previousTapped(_ sender: Any) {
        scrollWeek(by: -7)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        postsTableView.dataSource = self
        postsTableView.delegate = self
            
        applyPillStyle(to: savedButton)
        applyPillStyle(to: scheduledButton)
        applyPillStyle(to: publishedButton)
            
        let calendar = Calendar.current
            currentWeekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
            
            setupCustomCalendar(for: currentWeekStartDate) // Pass the starting date
            
            updateTableViewHeight()
    }
    func applyPillStyle(to button: UIButton) {
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
    }
    
    func setupCustomCalendar(for startDate: Date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM yyyy"
            monthLabel.text = dateFormatter.string(from: startDate)
            addWeekdayLabels()
            addDateViews(startingFrom: startDate)
    }
            
    func addWeekdayLabels() {
        let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        
        // NOTE: Corrected IBOutlet name to weekDayStackView
        weekDayStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
        for day in daysOfWeek {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .systemGray
            
            weekDayStackView.addArrangedSubview(label)
        }
    }
            
    func addDateViews(startingFrom startDate: Date) {
        let calendar = Calendar.current
            // NOTE: startDate is already the start of the week now.
            
            // Find a sample selected date (e.g., always the 3rd day of the starting week)
            guard let selectedDate = calendar.date(byAdding: .day, value: 3, to: startDate) else { return }
            
            dateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            for i in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
                let dateString = String(calendar.component(.day, from: date))
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let hasEvents = (i % 2 == 0)
                
                let dateContainer = createDateContainer(date: dateString, isSelected: isSelected, hasEvents: hasEvents, dayIndex: i)
                
                dateStackView.addArrangedSubview(dateContainer)
            }
    }
    func scrollWeek(by days: Int) {
        guard let newStartDate = Calendar.current.date(byAdding: .day, value: days, to: currentWeekStartDate) else { return }
        currentWeekStartDate = newStartDate
        setupCustomCalendar(for: currentWeekStartDate)
    }
    private func createDateContainer(date: String, isSelected: Bool, hasEvents: Bool, dayIndex: Int) -> UIView {
        let label = UILabel()
        label.text = date
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
            
        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -3)
            ])
        if isSelected {
            container.backgroundColor = .systemTeal.withAlphaComponent(70/255)
            container.layer.cornerRadius = 18
            container.clipsToBounds = true
            container.heightAnchor.constraint(equalToConstant: 36).isActive = true
        } else {
            container.heightAnchor.constraint(equalToConstant: 36).isActive = true
        }
        
        if hasEvents && !isSelected {
                let indicator = UIView()
                 if dayIndex < 3 {
                    indicator.backgroundColor = .systemGreen
                } else {
                    indicator.backgroundColor = .systemYellow
                }
                indicator.layer.cornerRadius = 2.5
                indicator.clipsToBounds = true
                indicator.translatesAutoresizingMaskIntoConstraints = false
                
                container.addSubview(indicator)
                
                NSLayoutConstraint.activate([
                    indicator.widthAnchor.constraint(equalToConstant: 5),
                    indicator.heightAnchor.constraint(equalToConstant: 5),
                    indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    indicator.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2)
                ])
            }
            
        return container
    }
            
    func updateTableViewHeight() {
        let cellHeight: CGFloat = 100
        
        let requiredHeight = CGFloat(todayScheduledPosts.count) * cellHeight
        tableViewHeightConstraint.constant = requiredHeight
        view.layoutIfNeeded()
    }
}
extension PostsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(todayScheduledPosts.count)
        return todayScheduledPosts.count
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostTableViewCell else {
            fatalError("Could not dequeue PostTableViewCell")
        }
            
        let post = todayScheduledPosts[indexPath.row]
        cell.configure(with: post)
            
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            todayScheduledPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

