import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

/// Listing lifecycle (additive — [available] / [soldOut] unchanged).
class ProductStatus {
  static const String available = 'available';
  static const String soldOut = 'sold_out';
  /// Admin-removed from public browse; not a hard delete.
  static const String removed = 'removed';

  static const List<String> values = [available, soldOut, removed];
}

@JsonSerializable(explicitToJson: true)
class ProductModel {
  final String id;
  final String vendorId;
  final String vendorName;
  final String campusId;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final List<String> imageUrls;

  /// One of [ProductStatus.values].
  final String status; // available, sold_out, removed
  final String condition; // new, used
  final int viewCount;
  final int likeCount;
  final List<String> searchKeywords;

  /// Why an admin removed this listing (null when not removed).
  final String? adminRemovalReason;

  @NullableTimestampConverter()
  final DateTime? adminRemovedAt;

  @TimestampConverter()
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.campusId,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.imageUrls,
    required this.status,
    required this.condition,
    required this.viewCount,
    required this.likeCount,
    required this.searchKeywords,
    this.adminRemovalReason,
    this.adminRemovedAt,
    required this.createdAt,
  });

  bool get isAdminRemoved => status == ProductStatus.removed;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

class NullableTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  dynamic toJson(DateTime? date) =>
      date == null ? null : Timestamp.fromDate(date);
}
