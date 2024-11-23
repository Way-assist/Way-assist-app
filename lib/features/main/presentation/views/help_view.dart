import 'package:wayassist/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  Future<void> _sendSMS(BuildContext context) async {
    const phoneNumber = '+51934399132';
    const message = '¡Necesito ayuda urgente!';

    try {
      await sendSMS(
        message: message,
        recipients: [phoneNumber],
        sendDirect: true,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje enviado')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Este dispositivo no puede enviar mensajes SMS.')),
      );
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    const phoneNumber = '+51984260169';
    final url = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'No se pudo realizar la llamada. Este dispositivo no tiene capacidad para llamadas.';
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Este dispositivo no puede realizar llamadas telefónicas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Zona de ayuda',
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: colors.surface),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: CustomFilledButton(
            text: 'Pedir ayuda',
            sizeText: 40,
            onPressed: () async {
              await _makePhoneCall(context);
              await _sendSMS(context);
            },
            borderColor: colors.secondary.withOpacity(0.2),
            textColor: colors.surface,
            buttonColor: colors.error,
            iconColor: colors.primary,
          ),
        ),
      ),
    );
  }
}
