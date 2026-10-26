//
//  OrdersFormViewController.swift
//  dabao
//
//  Created by Shofia Ghazali on 26/10/26.
//


import UIKit

protocol OrdersFormDelegate: AnyObject {
    func didAdd(_ order: Order)
}
class OrdersFormViewController: UIViewController {

    weak var delegate: OrdersFormDelegate?
    private let dishField = UITextField()
    private let stepper = UIStepper()
    private let drinkSwitch = UISwitch()
    private let quantityLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "New order"

        dishField.placeholder = "Dish"
        dishField.borderStyle = .roundedRect

        stepper.minimumValue = 1
        stepper.value = 1
        stepper.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.quantityLabel.text = "Quantity: \(Int(self.stepper.value))"
        }, for: .valueChanged)
        quantityLabel.text = "Quantity: 1"

        let drinkLabel = UILabel()
        drinkLabel.text = "Is this a drink?"

        let drinkRow = UIStackView(
            arrangedSubviews: [drinkLabel, drinkSwitch]
        )
        drinkRow.axis = .horizontal
        drinkRow.alignment = .center
        drinkRow.distribution = .equalSpacing

        let stack = UIStackView(
            arrangedSubviews: [dishField, drinkRow, quantityLabel, stepper]
        )
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        dishField.autocapitalizationType = .sentences
        dishField.returnKeyType = .done
        dishField.addAction(UIAction { [weak self] _ in self?.saveTapped() }, for: .primaryActionTriggered)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 24
            ),
            stack.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            )
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .save,
            primaryAction: UIAction { [weak self] _ in
                self?.saveTapped()
            }
        )
    }

    private func saveTapped() {
        let dish = dishField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !dish.isEmpty else { return }
        
        delegate?.didAdd(
            Order(dish: dish, quantity: Int(stepper.value), isDrink: drinkSwitch.isOn)
        )
        dismiss(animated: true)
    }
}


#Preview {
    OrdersFormViewController()
}
