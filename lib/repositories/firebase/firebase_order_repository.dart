import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order.dart';
import '../order_repository.dart';

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
    _firestore.collection('orders');

  @override
  Stream<List<FramingOrder>> watchCustomerOrders(String customerUid){
    return _ordersCollection
      .where('customerUid', isEqualTo: customerUid)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => FramingOrder.fromJson(doc.data()))
        .toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Stream<List<FramingOrder>> watchVendorOrders(String vendorId){
    return _ordersCollection
      .where('vendorId', isEqualTo: vendorId)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => FramingOrder.fromJson(doc.data()))
        .toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Future<void> submitOrder(FramingOrder order) async{
    await _ordersCollection.doc(order.id).set(order.toJson());
  }

  @override
  Future<void> updateStage(String orderId, OrderStage stage) async{
    await _ordersCollection.doc(orderId).update({'stage': stage.name});
  }
}  
