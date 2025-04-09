import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Common UI components for exercise screens
class ExerciseUIComponents {
  // App color palette
  static const Color primaryColor = Color(0xFFD2EB50); // Lime Green
  static const Color secondaryColor = Color(0xFF4682B4); // Steel Blue
  static const Color darkBackground = Color(0xFF1E293B); // Dark Blue-Gray
  
  // Status colors
  static const Color goodColor = Color(0xFF4CAF50); // Green
  static const Color warningColor = Color(0xFFFFA726); // Orange
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color inactiveColor = Color(0xFF9E9E9E); // Grey

  /// Enhanced status box showing a label and value with a stylish background
  static Widget buildStatusBox({
    required String label,
    required String value,
    required Color color,
    double fontSize = 16,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Improved rep counter with animation effect
  static Widget buildRepCounter({
    required int count,
    double size = 80,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.bebasNeue(
                color: Colors.black87,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'REPS',
              style: GoogleFonts.dmSans(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Status row with multiple status boxes
  static Widget buildStatusRow({
    required List<Widget> statusBoxes,
    double height = 80,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.9), 
            Colors.black.withOpacity(0.7)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: statusBoxes.map((widget) => Expanded(child: widget)).toList(),
      ),
    );
  }
  
  /// Enhanced feedback box with icon
  static Widget buildFeedbackBox({
    required String feedbackText,
    Color backgroundColor = Colors.black,
    double opacity = 0.8,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates,
            color: primaryColor,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              feedbackText,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                height: 1.3,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Improved instructions box
  static Widget buildInstructionsBox({
    required String instructionsText,
    Color backgroundColor = Colors.blue,
    double opacity = 0.8,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.assistant_direction,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              instructionsText,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Timer display for plank and duration-based exercises
  static Widget buildTimerDisplay({
    required int seconds,
    double size = 100,
  }) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    final String timeDisplay = '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    
    // Calculate progress percentage (assuming 2 minutes as target)
    final double progress = seconds / 120;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // Progress ring
          Center(
            child: SizedBox(
              width: size - 10,
              height: size - 10,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                strokeWidth: 8,
              ),
            ),
          ),
          
          // Time text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeDisplay,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TIME',
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get enhanced status color based on form status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'correct':
        return goodColor;
      case 'too narrow':
      case 'too far out': 
      case 'too wide':
      case 'half rep':
      case 'too high':  
      case 'too low':   
      case 'misaligned': 
        return errorColor;
      case 'curl higher':
      case 'extend fully':
      case 'warning':
      case 'needs correction': 
        return warningColor;
      case 'unk':
      default:
        return inactiveColor;
    }
  }
  
  /// Get icon based on status for richer visual feedback
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'correct':
        return Icons.check_circle;
      case 'too narrow':
        return Icons.compress;
      case 'too wide':
        return Icons.open_in_full;
      case 'too far out': 
        return Icons.arrow_outward;
      case 'half rep':
        return Icons.incomplete_circle;
      case 'too high':  
        return Icons.arrow_upward;
      case 'too low':   
        return Icons.arrow_downward;
      case 'curl higher':
        return Icons.trending_up;
      case 'extend fully':
        return Icons.expand;
      case 'needs correction': 
        return Icons.warning_amber;
      case 'unk':
      default:
        return Icons.help_outline;
    }
  }
}