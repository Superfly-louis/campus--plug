import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VendorModel {
  final String id;
  final String ownerId;
  final String businessName;
  final String description;
  final String logoUrl;
  final String bannerUrl;
  final List<String> categories;
  final double ratingAverage;
  final int ratingCount;
  final bool isVerified;
  final String whatsappNumber;
  final String campusId;
  final int? responseTimeMinutes;
  final String? category;

  @JsonKey(defaultValue: 0)
  final int completedOrders;

  @GeoPointConverter()
  final GeoPoint? location;

  @TimestampConverter()
  final DateTime createdAt;

  VendorModel({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.description,
    required this.logoUrl,
    required this.bannerUrl,
    required this.categories,
    required this.ratingAverage,
    required this.ratingCount,
    required this.isVerified,
    required this.whatsappNumber,
    required this.campusId,
    this.responseTimeMinutes,
    this.category,
    this.completedOrders = 0,
    this.location,
    required this.createdAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    // Inject category fallback from categories if category is missing
    if (json['category'] == null &&
        json['categories'] is List &&
        (json['categories'] as List).isNotEmpty) {
      json['category'] = (json['categories'] as List)[0];
    }
    // Inject campusId fallback from campusId or campus
    if (json['campusId'] == null && json['campus'] != null) {
      json['campusId'] = json['campus'];
    }
    return _$VendorModelFromJson(json);
  }
  Map<String, dynamic> toJson() => _$VendorModelToJson(this);
}

class GeoPointConverter implements JsonConverter<GeoPoint?, dynamic> {
  const GeoPointConverter();

  @override
  GeoPoint? fromJson(dynamic geo) {
    if (geo is GeoPoint) return geo;
    if (geo is Map) return GeoPoint(geo['latitude'], geo['longitude']);
    return null;
  }

  @override
  dynamic toJson(GeoPoint? geo) => geo;
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
