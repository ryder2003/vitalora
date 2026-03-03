import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import '../models/food_item.dart';

class FoodService {
  final String _model = 'gemini-1.5-pro';
  bool _isInitialized = false;

  // Load the API key from the environment
  String get _apiKey => dotenv.env['GOOGLE_AI_API_KEY'] ?? '';

  // Initialize Gemini in the constructor
  FoodService() {
    if (_apiKey.isNotEmpty) {
      Gemini.init(apiKey: _apiKey);
      _isInitialized = true;
    } else {
      print('Warning: Google AI API key not found. Food scanning will not work.');
    }
  }
Future<Either<String, FoodItem>> detectFoodAndCalories(File imageFile) async {
  try {
    if (!_isInitialized) {
      return Left('API key not configured. Please add your GOOGLE_AI_API_KEY to the .env file.');
    }

    if (!imageFile.existsSync()) {
      return Left('File not found: ${imageFile.path}');
    }

    final response = await Gemini.instance.textAndImage(
      text: 'Analyze this image and identify the food. '
          'Estimate its calories, protein, carbs, and fat. '
          'Return JSON in this format: {"name": "food name", "calories": 100, "protein": 10, "carbs": 20, "fat": 5}',
      images: [imageFile.readAsBytesSync()],
    );

    final output = response?.output;
    if (output == null || output.isEmpty) {
      return Left('No response output from Gemini API');
    }

    final match = RegExp(r'\{.*\}').firstMatch(output);
    if (match == null) {
      return Left('No valid JSON found in output: $output');
    }

    final foodData = jsonDecode(match.group(0)!);

    return Right(FoodItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: foodData['name'],
      calories: foodData['calories'].toDouble(),
      protein: foodData['protein'].toDouble(),
      carbs: foodData['carbs'].toDouble(),
      fat: foodData['fat'].toDouble(),
      quantity: 100.0,
      timestamp: DateTime.now(),
    ));
  } catch (e) {
    return Left('Failed to detect food: ${e.toString()}');
  }
}
}