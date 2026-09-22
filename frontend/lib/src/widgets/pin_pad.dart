import 'package:flutter/material.dart';

import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';

/// Teclado numérico para ingresar un PIN de 4 dígitos.
class PadPin extends StatefulWidget {
  const PadPin({super.key});

  @override
  State<PadPin> createState() => _PadPinState();
}

class _PadPinState extends State<PadPin> with SingleTickerProviderStateMixin {
  String _pin = '';
  String _error = '';

  void _tecla(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = '';
    });
  }

  void _borrar() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Puntitos(pin: _pin, error: _error, paleta: paleta),
        const SizedBox(height: spacingLg),
        for (var fila = 0; fila < 3; fila++)
          _FilaTeclas(
            paleta: paleta,
            teclas: ['1', '2', '3'].map((e) => (fila * 3 + int.parse(e)).toString()).toList(),
            alTocar: _tecla,
            mostrar: true,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Tecla(paleta: paleta, rotulo: '', mostrado: false, alTocar: () {}),
            _Tecla(paleta: paleta, rotulo: '0', mostrado: true, alTocar: () => _tecla('0')),
            _Tecla(
              paleta: paleta,
              rotulo: 'del',
              mostrado: false,
              esBorrar: true,
              alTocar: _borrar,
            ),
          ],
        ),
      ],
    );
  }
}

class _Puntitos extends StatelessWidget {
  final String pin;
  final String error;
  final Paleta paleta;

  const _Puntitos({required this.pin, required this.error, required this.paleta});

  @override
  Widget build(BuildContext context) {
    final tieneError = error.isNotEmpty;
    final color = tieneError ? paleta.danger : paleta.gold;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final lleno = i < pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: spacingSm),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lleno ? color : Colors.transparent,
                border: Border.all(color: color, width: 1.6),
              ),
            );
          }),
        ),
        if (tieneError) ...[
          const SizedBox(height: spacingSm),
          Text(error, style: TextStyle(color: paleta.danger, fontSize: 13)),
        ],
      ],
    );
  }
}

class _FilaTeclas extends StatelessWidget {
  final Paleta paleta;
  final List<String> teclas;
  final ValueChanged<String> alTocar;
  final bool mostrar;

  const _FilaTeclas({
    required this.paleta,
    required this.teclas,
    required this.alTocar,
    required this.mostrar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: teclas
          .map((t) => Padding(
                padding: const EdgeInsets.all(spacingSm),
                child: _Tecla(
                  paleta: paleta,
                  rotulo: t,
                  mostrado: mostrar,
                  alTocar: () => alTocar(t),
                ),
              ))
          .toList(),
    );
  }
}

class _Tecla extends StatelessWidget {
  final Paleta paleta;
  final String rotulo;
  final bool mostrado;
  final bool esBorrar;
  final VoidCallback alTocar;

  const _Tecla({
    required this.paleta,
    required this.rotulo,
    this.mostrado = true,
    this.esBorrar = false,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(radiusPill),
      onTap: alTocar,
      child: Container(
        width: 74,
        height: 62,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: paleta.cardLight,
          borderRadius: BorderRadius.circular(radiusLg),
          border: Border.all(color: paleta.borderSubtle),
        ),
        child: esBorrar
            ? Icon(Icons.backspace_outlined, color: paleta.textMuted, size: 22)
            : Text(
                rotulo,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: mostrado ? paleta.text : paleta.cardLight,
                ),
              ),
      ),
    );
  }
}

/// Abre un diálogo que pide un PIN; devuelve el PIN (4 dígitos) o null.
/// Opcionalmente valida el PIN ingresado contra [validar] (debe devolver
/// mensaje de error o null si es correcto).
Future<String?> pedirPin(
  BuildContext context, {
  String titulo = 'Ingresa tu PIN',
  String? mensaje,
  Future<String?> Function(String pin)? validar,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PinDialogo(
      titulo: titulo,
      mensaje: mensaje,
      validar: validar,
    ),
  );
}

class _PinDialogo extends StatefulWidget {
  final String titulo;
  final String? mensaje;
  final Future<String?> Function(String pin)? validar;

  const _PinDialogo({required this.titulo, this.mensaje, this.validar});

  @override
  State<_PinDialogo> createState() => _PinDialogoState();
}

class _PinDialogoState extends State<_PinDialogo> {
  String _pin = '';
  bool _cargando = false;
  String _error = '';

  Future<void> _confirmar() async {
    if (_pin.length != 4 || _cargando) return;
    final validar = widget.validar;
    if (validar == null) {
      Navigator.of(context).pop(_pin);
      return;
    }
    setState(() => _cargando = true);
    final err = await validar(_pin);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (err == null) {
        Navigator.of(context).pop(_pin);
      } else {
        _error = err;
        _pin = '';
      }
    });
  }

  void _tecla(String d) {
    if (_pin.length >= 4 || _cargando) return;
    setState(() {
      _pin += d;
      _error = '';
      if (_pin.length == 4) {
        Future.microtask(_confirmar);
      }
    });
  }

  void _borrar() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.mensaje != null) ...[
            Text(widget.mensaje!,
                style: TextStyle(color: paleta.textMuted, fontSize: 13)),
            const SizedBox(height: spacingMd),
          ],
          _Puntitos(pin: _pin, error: _error, paleta: paleta),
          const SizedBox(height: spacingMd),
          _TecladoFK(
            paleta: paleta,
            alDigito: _tecla,
            alBorrar: _borrar,
          ),
          if (_cargando) ...[
            const SizedBox(height: spacingSm),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cargando
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _TecladoFK extends StatelessWidget {
  final Paleta paleta;
  final ValueChanged<String> alDigito;
  final VoidCallback alBorrar;

  const _TecladoFK({
    required this.paleta,
    required this.alDigito,
    required this.alBorrar,
  });

  @override
  Widget build(BuildContext context) {
    const filas = <List<String>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final fila in filas)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fila
                .map((d) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: _TeclaFK(
                        paleta: paleta,
                        rotulo: d,
                        alTocar: () => alDigito(d),
                      ),
                    ))
                .toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 70, height: 62),
            Padding(
              padding: const EdgeInsets.all(4),
              child: _TeclaFK(
                paleta: paleta,
                rotulo: '0',
                alTocar: () => alDigito('0'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: _TeclaBorrar(paleta: paleta, alTocar: alBorrar),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeclaFK extends StatelessWidget {
  final Paleta paleta;
  final String rotulo;
  final VoidCallback alTocar;

  const _TeclaFK({required this.paleta, required this.rotulo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(radiusLg),
      child: Container(
        width: 70,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: paleta.cardLight,
          borderRadius: BorderRadius.circular(radiusLg),
          border: Border.all(color: paleta.borderSubtle),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: paleta.text,
          ),
        ),
      ),
    );
  }
}

class _TeclaBorrar extends StatelessWidget {
  final Paleta paleta;
  final VoidCallback alTocar;

  const _TeclaBorrar({required this.paleta, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(radiusLg),
      child: Container(
        width: 70,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: paleta.cardLight,
          borderRadius: BorderRadius.circular(radiusLg),
          border: Border.all(color: paleta.borderSubtle),
        ),
        child: Icon(Icons.backspace_outlined, color: paleta.textMuted, size: 22),
      ),
    );
  }
}