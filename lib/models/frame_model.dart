import 'package:flutter/material.dart';

class FrameModel {
  final String id;
  final String name;
  final String imageUrl; 
  final Rect centerSlice; 

  FrameModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.centerSlice,
  });
}