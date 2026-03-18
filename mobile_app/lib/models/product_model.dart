import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

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
  final String status; // available, sold_out
  final String condition; // new, used
  final int viewCount;
  final int likeCount;
  final List<String> searchKeywords;
  
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
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
