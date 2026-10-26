//
//  OrdersViewController.swift
//  dabao
//
//  Created by Shofia Ghazali on 26/10/26.
//

import UIKit

class OrdersViewController: UIViewController,
                            OrdersFormDelegate,
                            UITableViewDelegate{
    
    private let fileURL = URL.documentsDirectory.appending(path: "orders.json")
    
    nonisolated enum Section: String { case drinks = "Drinks", food = "Food" }
    
    private let tableView = UITableView()
    
    private var orders: [Order] = [
        Order(dish: "Chicken rice", quantity: 1, isDrink: false),
        Order(dish: "Teh peng", quantity: 2, isDrink: true),
        Order(dish: "Roti prata", quantity: 3, isDrink: false)
    ]
    
    private var dataSource: OrdersDataSource!
    
    //private var dataSource: OrdersDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "Orders"
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        
        dataSource = OrdersDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            // Snapshot items are matched by id, so read the latest values from the model
            let order = self?.orders.first { $0.id == item.id } ?? item
            var content = cell.defaultContentConfiguration()
            content.text = order.dish
            content.secondaryText = "x\(order.quantity)"
            content.secondaryTextProperties.font = .preferredFont(forTextStyle: .headline)
            content.prefersSideBySideTextAndSecondaryText = true
            content.image = UIImage(systemName: order.isDrink ? "cup.and.saucer.fill" : "fork.knife")
            cell.contentConfiguration = content
            return cell
        }
        dataSource.defaultRowAnimation = .fade

        load()
        applySnapshot()
        let addButton = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in
                self?.showAdd()
            }
        )
        let surpriseButton = UIBarButtonItem(
            image: UIImage(systemName: "dice.fill"),
            primaryAction: UIAction { [weak self] _ in self?.surpriseMe() }
        )
        navigationItem.rightBarButtonItems = [addButton, surpriseButton]
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Clear",
            primaryAction: UIAction { [weak self] _ in self?.clearAll() }
        )
        updateEmptyState()
        tableView.delegate = self
        
        print(fileURL)
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Order>()
        
        let drinks = orders.filter { $0.isDrink }
        let food = orders.filter { !$0.isDrink }

        // Only show sections that have items
        if !drinks.isEmpty {
            snapshot.appendSections([.drinks])
            snapshot.appendItems(drinks, toSection: .drinks)
        }
        if !food.isEmpty {
            snapshot.appendSections([.food])
            snapshot.appendItems(food, toSection: .food)
        }
        snapshot.reconfigureItems(orders)

        let total = orders.reduce(0) { $0 + $1.quantity }
        title = total == 0 ? "Orders" : "Orders (\(total))"
        updateEmptyState()

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func showAdd() {
        let addVC = OrdersFormViewController()
        addVC.delegate = self
        present(UINavigationController(rootViewController: addVC), animated: true)
    }
    
    // "Can't decide what to dabao?" Let fate pick a Singapore classic
    private static let menu: [(dish: String, emoji: String, isDrink: Bool)] = [
        ("Laksa", "🍜", false), ("Chilli crab", "🦀", false), ("Char kway teow", "🍝", false),
        ("Satay", "🍢", false), ("Nasi lemak", "🍛", false), ("Hokkien mee", "🍤", false),
        ("Kaya toast", "🍞", false), ("Bak chor mee", "🥢", false),
        ("Kopi O", "☕️", true), ("Milo dinosaur", "🦖", true), ("Teh tarik", "🫖", true),
        ("Bandung", "🌹", true), ("Sugarcane juice", "🎋", true)
    ]

    private func surpriseMe() {
        guard let pick = Self.menu.randomElement() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let alert = UIAlertController(
            title: "\(pick.emoji) \(pick.dish)!",
            message: "Fate says you should dabao this. Add it?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            self?.didAdd(Order(dish: pick.dish, quantity: 1, isDrink: pick.isDrink))
        })
        alert.addAction(UIAlertAction(title: "Roll again", style: .default) { [weak self] _ in
            self?.surpriseMe()
        })
        alert.addAction(UIAlertAction(title: "Nah", style: .cancel))
        present(alert, animated: true)
    }

    func didAdd(_ order: Order) {
        // Merge duplicates instead of listing the same dish twice
        if let index = orders.firstIndex(where: {
            $0.dish.caseInsensitiveCompare(order.dish) == .orderedSame && $0.isDrink == order.isDrink
        }) {
            orders[index].quantity += order.quantity
        } else {
            orders.append(order)
        }
        save()
        applySnapshot()
    }
    
    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(orders)
            try data.write(to: fileURL)
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode([Order].self, from: data) else { return }
        orders = saved
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let order = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completionHandler in
            
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            self.orders.removeAll { $0 == order }
            self.save()
            self.applySnapshot()
            
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let order = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let minus = UIContextualAction(style: .normal, title: "-1") { [weak self] _, _, done in
            self?.changeQuantity(of: order, by: -1)
            done(true)
        }
        minus.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [minus])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let order = dataSource.itemIdentifier(for: indexPath) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        changeQuantity(of: order, by: 1)
    }

    // Quantity reaching 0 removes the order
    private func changeQuantity(of order: Order, by delta: Int) {
        guard let index = orders.firstIndex(where: { $0.id == order.id }) else { return }
        orders[index].quantity += delta
        if orders[index].quantity <= 0 {
            orders.remove(at: index)
        }
        save()
        applySnapshot()
    }

    private func clearAll() {
        let alert = UIAlertController(title: "Clear all orders?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.orders.removeAll()
            self?.save()
            self?.applySnapshot()
        })
        present(alert, animated: true)
    }

    private func updateEmptyState() {
        if orders.isEmpty {
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "bag")
            config.text = "No orders yet"
            config.secondaryText = "Tap + to add food or drinks"
            contentUnavailableConfiguration = config
        } else {
            contentUnavailableConfiguration = nil
        }
        navigationItem.leftBarButtonItem?.isEnabled = !orders.isEmpty
    }
}

#Preview {
    OrdersViewController()
}

