import StoreKit
import Observation

/// Lexicurio Pro: a one-time, non-consumable purchase that removes all ads
/// and makes practice hints free. Uses StoreKit 2.
@MainActor
@Observable
final class StoreManager {
    static let proProductID = "com.lexicurio.app.pro"

    private(set) var pro: Product?
    private(set) var isAdFree = UserDefaults.standard.bool(forKey: "lx.pro")
    private(set) var purchaseInFlight = false
    var message: String?

    private var updates: Task<Void, Never>?

    func start() async {
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.handle(result) }
        }
        do { pro = try await Product.products(for: [Self.proProductID]).first }
        catch { message = "Could not reach the App Store. Try again later." }
        await refreshEntitlement()
    }

    func buy() async {
        guard let pro else { return }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            switch try await pro.purchase() {
            case .success(let result): await handle(result)
            case .pending: message = "Purchase is waiting for approval."
            case .userCancelled: break
            @unknown default: break
            }
        } catch {
            message = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        do { try await AppStore.sync() } catch { message = "Restore failed: \(error.localizedDescription)" }
        await refreshEntitlement()
        if !isAdFree { message = "No previous Lexicurio Pro purchase found for this Apple ID." }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let t) = result else { return }
        if t.productID == Self.proProductID { setAdFree(t.revocationDate == nil) }
        await t.finish()
    }

    private func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.proProductID, t.revocationDate == nil { owned = true }
        }
        setAdFree(owned)
    }

    private func setAdFree(_ value: Bool) {
        isAdFree = value
        UserDefaults.standard.set(value, forKey: "lx.pro")
    }
}
