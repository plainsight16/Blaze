import 'package:flutter/material.dart';

class GroupData {
  const GroupData({
    this.id,
    required this.name,
    this.description,
    this.type,
    required this.members,
    required this.capacityFraction,
    required this.target,
    required this.tag,
    required this.tagColor,
    required this.icon,
  });

  final String? id;
  final String name;
  final String? description;
  final String? type;
  final int members;
  final double capacityFraction;
  final String target;
  final String tag;
  final Color tagColor;
  final IconData icon;
}
