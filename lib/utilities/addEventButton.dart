import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEventButton extends StatelessWidget {
  final String label;
  final Function()? onTap;

  const AddEventButton({super.key, required this.label, required this.onTap}); 
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.white, 
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              wordSpacing: 1,
              
              
            ),
          ),
        ),
      ),
    );
  }
}
