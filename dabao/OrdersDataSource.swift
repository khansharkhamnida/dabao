//
//  OrdersDataSource.swift
//  dabao
//
//  Created by Shofia Ghazali on 26/10/26.
//

import UIKit

// Adds section titles (Drinks / Food) to the diffable data source
final class OrdersDataSource: UITableViewDiffableDataSource<OrdersViewController.Section, Order> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionIdentifier(for: section)?.rawValue
    }
}
