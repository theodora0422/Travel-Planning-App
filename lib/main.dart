import 'package:flutter/material.dart';
import 'package:travel_planning_app/features/home/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const TravelPlanningApp());
}
class TravelPlanningApp extends StatelessWidget{
  const TravelPlanningApp({super.key});
  @override
  Widget build (BuildContext context){
    return MaterialApp(
      title: 'Travel Planning App',
      theme: AppTheme.lightTheme,
      home:HomeScreen(),
    );
  }
}