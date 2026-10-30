import '../models/order.dart';

/// Framing orders between customers and workshops. Implemented with a
/// Firestore `orders` collection.
abstract interface class OrderRepository {
  /// Orders a customer (artist or gallery) has placed, newest first.
  Stream<List<FramingOrder>> watchCustomerOrders(String customerUid);

  /// Orders a workshop has received, newest first.
  Stream<List<FramingOrder>> watchVendorOrders(String vendorId);

  Future<void> submitOrder(FramingOrder order);

  /// Moves an order to [stage] (the workshop's production tracker).
  Future<void> updateStage(String orderId, OrderStage stage);

  /// Sets the workshop's confirmed price.
  Future<void> setQuote(String orderId, double quoteRm);
}
