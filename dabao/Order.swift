
import Foundation

nonisolated struct Order: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var dish: String
    var quantity: Int
    var isDrink: Bool

    init(
        id: UUID = UUID(),
        dish: String,
        quantity: Int,
        isDrink: Bool
    ) {
        self.id = id
        self.dish = dish
        self.quantity = quantity
        self.isDrink = isDrink
    }
    
    // Identity by id only, so a quantity change is an update, not a new item
    nonisolated static func == (lhs: Order, rhs: Order) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
