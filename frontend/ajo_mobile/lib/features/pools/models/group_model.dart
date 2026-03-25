import 'package:flutter/material.dart';

class GroupData {
  const GroupData({
    required this.name,
    required this.members,
    required this.capacityFraction,
    required this.target,
    required this.tag,
    required this.tagColor,
    required this.icon,
  });

  final String name;
  final int members;
  final double capacityFraction;
  final String target;
  final String tag;
  final Color tagColor;
  final IconData icon;
}
