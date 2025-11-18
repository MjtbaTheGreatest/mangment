import 'dart:ui';
import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

/// حقل نص زجاجي أنيق بتصميم iOS 18
class GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _isObscured = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // التسمية
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            widget.label,
            style: AppTextStyles.inputLabel.copyWith(
              color: _isFocused ? AppColors.textGold : AppColors.textSecondary,
            ),
          ),
        ),

        // الحقل الزجاجي
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.primaryGold.withOpacity(0.5)
                        : AppColors.glassWhite,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (_isFocused)
                      BoxShadow(
                        color: AppColors.primaryGold.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.glassWhite,
                            AppColors.glassWhite.withOpacity(0.5),
                          ],
                        ),
                      ),
                      child: TextFormField(
                        controller: widget.controller,
                        obscureText: widget.isPassword && _isObscured,
                        keyboardType: widget.keyboardType,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.inputText,
                        validator: widget.validator,
                        onTap: () {
                          setState(() => _isFocused = true);
                          _animationController.forward();
                        },
                        onEditingComplete: () {
                          setState(() => _isFocused = false);
                          _animationController.reverse();
                        },
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          hintStyle: AppTextStyles.inputHint,
                          border: InputBorder.none,
                          prefixIcon: widget.isPassword
                              ? IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return RotationTransition(
                                        turns: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      _isObscured
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      key: ValueKey(_isObscured),
                                      size: 22,
                                      color: _isFocused
                                          ? AppColors.primaryGold
                                          : AppColors.lightGray,
                                    ),
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                )
                              : null,
                          suffixIcon: Icon(
                            widget.icon,
                            color: _isFocused
                                ? AppColors.primaryGold
                                : AppColors.lightGray,
                            size: 22,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
