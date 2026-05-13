import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'application_form_page_mobile.dart';
import 'application_form_page_web.dart';

class ApplicationFormPage extends StatelessWidget {
  const ApplicationFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: ApplicationFormPageMobile(),
      webScaffold: ApplicationFormWeb(),
    );
  }
}