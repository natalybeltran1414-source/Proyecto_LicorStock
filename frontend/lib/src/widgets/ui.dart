import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';

/// Etiqueta de un enum por mapa de traducción, con fallback.
String texti(String? valor, Map<String, String> mapa) =>
    (valor == null) ? '' : (mapa[valor] ?? valor);

void snaki(BuildContext context, String mensaje, {bool ok = true}) {
  final paleta = useTema(context).paleta;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.error_outline,
                color: ok ? paleta.success : paleta.danger, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: paleta.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: paleta.border),
        ),
      ),
    );
}

Future<void> dialogi(
  BuildContext context, {
  required String titulo,
  String? mensaje,
  IconData icono = Icons.info_outline,
  Color? colorIcono,
}) {
  final paleta = useTema(context).paleta;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono,
                  size: 22,
                  color: colorIcono ?? paleta.info),
              if (mensaje != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(mensaje, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Diálogo de confirmación; devuelve `true` si el usuario confirmó.
Future<bool> dialogConfirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoOk = 'Sí',
  String textoCancelar = 'No',
  bool peligro = false,
}) async {
  final paleta = useTema(context).paleta;
  final confirmo = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(textoCancelar,
              style: TextStyle(color: paleta.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: peligro ? paleta.danger : paleta.gold,
          ),
          child: Text(textoOk),
        ),
      ],
    ),
  );
  return confirmo ?? false;
}

/// Selector de color para categorías; devuelve el color elegido o null.
Future<Color?> dialogoColores(BuildContext context) {
  final paleta = useTema(context).paleta;
  return showDialog<Color>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Elige un color'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: paletaCategorias.map((c) {
          return InkWell(
            borderRadius: BorderRadius.circular(radiusPill),
            onTap: () => Navigator.of(ctx).pop(c),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: paleta.border),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

/// Campo de texto con etiqueta flotante y borde dorado al enfocar.
class CampoTexto extends StatefulWidget {
  final String etiqueta;
  final TextEditingController? controlador;
  final String? error;
  final bool esContrasena;
  final bool esNumero;
  final bool esDinero;
  final TextInputType textoTeclado;
  final TextInputAction accion;
  final bool autoCorreccion;
  final int? maxLongitud;
  final int? maxLineas;
  final String? sufijo;
  final String? prefijo;
  final String? valorInicial;
  final bool centrar;
  final bool habilitado;
  final ValueChanged<String>? alCambiar;
  final ValueChanged<String>? alEnviar;
  final FocusNode? foco;

  const CampoTexto({
    super.key,
    required this.etiqueta,
    this.controlador,
    this.error,
    this.esContrasena = false,
    this.esNumero = false,
    this.esDinero = false,
    this.textoTeclado = TextInputType.text,
    this.accion = TextInputAction.next,
    this.autoCorreccion = false,
    this.maxLongitud,
    this.maxLineas,
    this.sufijo,
    this.prefijo,
    this.valorInicial,
    this.centrar = false,
    this.habilitado = true,
    this.alCambiar,
    this.alEnviar,
    this.foco,
  });

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _oculto = true;
  bool _enfocado = false;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controlador ?? TextEditingController();
    if (widget.valorInicial != null) {
      _ctrl.text = widget.valorInicial!;
    }
    _focus = widget.foco ?? FocusNode();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant CampoTexto old) {
    super.didUpdateWidget(old);
    if (widget.valorInicial != null && old.valorInicial != widget.valorInicial) {
      _ctrl.text = widget.valorInicial!;
    }
  }

  @override
  void dispose() {
    if (widget.controlador == null) _ctrl.dispose();
    if (widget.foco == null) _focus.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() => _enfocado = _focus.hasFocus);

  List<TextInputFormatter> _formatters() {
    final lista = <TextInputFormatter>[];
    if (widget.esNumero || widget.esDinero) {
      lista.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')));
    }
    if (widget.maxLongitud != null) {
      lista.add(LengthLimitingTextInputFormatter(widget.maxLongitud));
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final esquinas = BorderRadius.circular(radiusMd);
    return Container(
      decoration: BoxDecoration(
        color: paleta.cardLight,
        borderRadius: esquinas,
        border: Border.all(
          color: widget.error != null
              ? paleta.danger
              : (_enfocado ? paleta.gold : paleta.borderSubtle),
          width: _enfocado ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(spacingMd, spacingSm, spacingMd, 0),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 14, color: paleta.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.error!,
                      style: TextStyle(fontSize: 12, color: paleta.danger),
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            enabled: widget.habilitado,
            obscureText: widget.esContrasena && _oculto,
            keyboardType: widget.esDinero
                ? TextInputType.numberWithOptions(decimal: true)
                : widget.esNumero
                    ? TextInputType.number
                    : widget.textoTeclado,
            textInputAction: widget.accion,
            autocorrect: widget.autoCorreccion,
            enableSuggestions: widget.autoCorreccion,
            maxLines: widget.esContrasena ? 1 : (widget.maxLineas ?? 1),
            onSubmitted: widget.alEnviar,
            onChanged: widget.alCambiar,
            inputFormatters: _formatters(),
            textAlign: widget.centrar ? TextAlign.center : TextAlign.start,
            style: TextStyle(color: paleta.text),
            decoration: InputDecoration(
              labelText: widget.etiqueta,
              labelStyle: TextStyle(
                color: widget.error != null
                    ? paleta.danger
                    : (_enfocado ? paleta.gold : paleta.textMuted),
              ),
              prefixText: widget.prefijo,
              suffixText: widget.sufijo,
              prefixStyle: TextStyle(color: paleta.textMuted),
              suffixStyle: TextStyle(color: paleta.textMuted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: spacingMd, vertical: spacingMd),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón principal dorado con degradado.
class BotonSolido extends StatelessWidget {
  final String titulo;
  final IconData? icono;
  final VoidCallback? alTocar;
  final bool cargando;
  final bool compacto;

  const BotonSolido({
    super.key,
    required this.titulo,
    this.icono,
    this.alTocar,
    this.cargando = false,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusPill),
        onTap: cargando ? null : alTocar,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radiusPill),
            gradient: LinearGradient(colors: paleta.gradientGold),
            boxShadow: paleta.sombraDorada(),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? spacingLg : spacingXl,
            vertical: compacto ? spacingSm : spacingMd - 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (cargando) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: paleta.sobreDorado,
                  ),
                ),
                const SizedBox(width: spacingSm),
              ] else if (icono != null) ...[
                Icon(icono, size: 20, color: paleta.sobreDorado),
                const SizedBox(width: spacingSm),
              ],
              Text(
                titulo,
                style: TextStyle(
                  color: paleta.sobreDorado,
                  fontWeight: FontWeight.w800,
                  fontSize: compacto ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de contorno dorado.
class BotonFantasma extends StatelessWidget {
  final String titulo;
  final IconData? icono;
  final VoidCallback? alTocar;
  final bool cargando;

  const BotonFantasma({
    super.key,
    required this.titulo,
    this.icono,
    this.alTocar,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return OutlinedButton.icon(
      onPressed: cargando ? null : alTocar,
      style: OutlinedButton.styleFrom(
        foregroundColor: paleta.gold,
        side: BorderSide(color: paleta.gold.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd - 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
      icon: cargando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icono, size: 18),
      label: Text(titulo),
    );
  }
}

/// Botón circular para acciones de barra superior.
class BotonIcono extends StatelessWidget {
  final IconData icono;
  final VoidCallback? alTocar;
  final Color? color;

  const BotonIcono({super.key, required this.icono, this.alTocar, this.color});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusPill),
        onTap: alTocar,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: paleta.cardLight,
            shape: BoxShape.circle,
            border: Border.all(color: paleta.borderSubtle),
          ),
          child: Icon(
            icono,
            size: 20,
            color: color ?? paleta.gold,
          ),
        ),
      ),
    );
  }
}

/// Botón flotante extendido con degradado dorado.
class FabExtendido extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final VoidCallback? alTocar;

  const FabExtendido({
    super.key,
    required this.titulo,
    required this.icono,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return FloatingActionButton.extended(
      onPressed: alTocar,
      backgroundColor: paleta.gold,
      foregroundColor: paleta.sobreDorado,
      elevation: paleta.shadowGoldElev,
      heroTag: titulo,
      icon: Icon(icono, size: 20),
      label: Text(
        titulo,
        style: TextStyle(
          color: paleta.sobreDorado,
          fontWeight: FontWeight.w800,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusPill),
      ),
    );
  }
}

/// Esqueleto de carga con pulso.
class Esqueleto extends StatefulWidget {
  final double ancho;
  final double alto;
  final double radio;

  const Esqueleto({
    super.key,
    this.ancho = double.infinity,
    this.alto = 18,
    this.radio = radiusSm,
  });

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.3,
    upperBound: 0.9,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Opacity(
        opacity: _ctrl.value,
        child: Container(
          width: widget.ancho,
          height: widget.alto,
          decoration: BoxDecoration(
            color: paleta.cardLight,
            borderRadius: BorderRadius.circular(widget.radio),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de carga (líneas pulso).
class EsqueletoTarjeta extends StatelessWidget {
  const EsqueletoTarjeta({super.key});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Esqueleto(ancho: 90, alto: 14),
          SizedBox(height: spacingMd),
          Esqueleto(alto: 13),
          SizedBox(height: spacingSm),
          Esqueleto(ancho: 220, alto: 13),
          SizedBox(height: spacingMd),
          Esqueleto(ancho: 140, alto: 13),
        ],
      ),
    );
  }
}

/// Tarjeta de dato (icono + etiqueta + valor).
class TarjetaInfo extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color color;
  final bool suave;
  final VoidCallback? alTocar;
  final Widget? extra;

  const TarjetaInfo({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
    this.suave = true,
    this.alTocar,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusLg),
        onTap: alTocar,
        child: Ink(
          padding: const EdgeInsets.all(spacingMd),
          decoration: BoxDecoration(
            color: paleta.card,
            borderRadius: BorderRadius.circular(radiusLg),
            border: Border.all(color: paleta.borderSubtle),
            boxShadow: paleta.sombraCard(),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: suave ? 0.16 : 1),
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child: Icon(icono, size: 20, color: color),
              ),
              const SizedBox(width: spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etiqueta,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: paleta.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (extra != null) extra!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado vacío con icono.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? textoAccion;
  final VoidCallback? alTocar;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.textoAccion,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: paleta.goldSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 40, color: paleta.gold),
            ),
            const SizedBox(height: spacingLg),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (mensaje != null) ...[
              const SizedBox(height: spacingSm),
              Text(
                mensaje!,
                textAlign: TextAlign.center,
                style: TextStyle(color: paleta.textMuted, fontSize: 14),
              ),
            ],
            if (textoAccion != null && alTocar != null) ...[
              const SizedBox(height: spacingLg),
              BotonFantasma(titulo: textoAccion!, icono: Icons.add, alTocar: alTocar),
            ],
          ],
        ),
      ),
    );
  }
}

/// Avatar circular con iniciales.
class Chat extends StatelessWidget {
  final String? nombre;
  final double tamanho;
  final Color? color;

  const Chat({super.key, this.nombre, this.tamanho = 54, this.color});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final letras = iniciales(nombre);
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: color ?? paleta.gold,
        gradient: LinearGradient(colors: paleta.gradientGold),
        shape: BoxShape.circle,
        border: Border.all(color: paleta.border, width: 1.4),
        boxShadow: paleta.sombraCard(),
      ),
      alignment: Alignment.center,
      child: Text(
        letras,
        style: TextStyle(
          color: paleta.sobreDorado,
          fontWeight: FontWeight.w800,
          fontSize: tamanho * 0.36,
        ),
      ),
    );
  }
}

/// Insignia de estado (pill de color).
class Badge extends StatelessWidget {
  final String texto;
  final Color color;
  final Color? fondo;
  final IconData? icono;

  const Badge({
    super.key,
    required this.texto,
    required this.color,
    this.fondo,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final bg = fondo ?? color.withValues(alpha: 0.14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de estado de venta (Activa / Anulada).
class BadgeEstado extends StatelessWidget {
  final bool activa;
  final Paleta paleta;

  const BadgeEstado({super.key, required this.activa, required this.paleta});

  @override
  Widget build(BuildContext context) {
    return Badge(
      texto: activa ? 'Activa' : 'Anulada',
      color: activa ? paleta.success : paleta.danger,
      icono: activa ? Icons.check_circle_outline : Icons.block,
    );
  }
}

/// Encabezado de página con marca (logo + ordenación).
class Marcaje extends StatelessWidget {
  final String titulo;
  final String? subtitulo;

  const Marcaje({super.key, this.titulo = '', this.subtitulo});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: paleta.gradientGold),
                borderRadius: BorderRadius.circular(radiusSm),
              ),
              child: Icon(Icons.local_bar, size: 18, color: paleta.sobreDorado),
            ),
            const SizedBox(width: spacingSm),
            Text(
              'LicorStock',
              style: TextStyle(
                color: paleta.gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: spacingLg),
        Text(titulo, style: tipoDisplay),
        if (subtitulo != null) ...[
          const SizedBox(height: spacingSm),
          Text(
            subtitulo!,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ],
    );
  }
}

/// Campo de búsqueda con icono y botón para limpiar.
class CampoBuscar extends StatefulWidget {
  final String etiqueta;
  final ValueChanged<String> alCambiar;
  final String? valorInicial;

  const CampoBuscar({
    super.key,
    this.etiqueta = 'Buscar…',
    required this.alCambiar,
    this.valorInicial,
  });

  @override
  State<CampoBuscar> createState() => _CampoBuscarState();
}

class _CampoBuscarState extends State<CampoBuscar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.valorInicial ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return TextField(
      controller: _ctrl,
      onChanged: widget.alCambiar,
      style: TextStyle(color: paleta.text),
      decoration: InputDecoration(
        hintText: widget.etiqueta,
        hintStyle: TextStyle(color: paleta.textMuted),
        prefixIcon: Icon(Icons.search, color: paleta.textMuted),
        suffixIcon: _ctrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                color: paleta.textMuted,
                onPressed: () {
                  _ctrl.clear();
                  widget.alCambiar('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: paleta.cardLight,
        contentPadding:
            const EdgeInsets.symmetric(vertical: spacingMd - 2, horizontal: spacingMd),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: paleta.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: paleta.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: paleta.gold, width: 1.6),
        ),
      ),
    );
  }
}

/// Transforma el texto de un campo tipo "01,250.00" a double.
double? parsearNumero(Object? texto) {
  if (texto == null) return null;
  try {
    return double.tryParse(texto.toString().replaceAll(',', '.')) ?? 0;
  } catch (_) {
    return null;
  }
}

/// Campo con botón para subir/limpiar imagen (producto).
class CampoImagen extends StatelessWidget {
  final String? url;
  final VoidCallback? alElegir;
  final VoidCallback? alQuitar;
  final double alto;

  const CampoImagen({
    super.key,
    this.url,
    this.alElegir,
    this.alQuitar,
    this.alto = 200,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      height: alto,
      decoration: BoxDecoration(
        color: paleta.cardLight,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url!.isNotEmpty)
            Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _SinImagen(),
            )
          else
            const _SinImagen(),
          Positioned(
            right: spacingSm,
            bottom: spacingSm,
            child: Row(
              children: [
                BotonIcono(icono: Icons.delete_outline, alTocar: alQuitar),
                const SizedBox(width: spacingSm),
                BotonIcono(icono: Icons.photo_camera_outlined, alTocar: alElegir),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinImagen extends StatelessWidget {
  const _SinImagen();

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 40, color: paleta.textMuted),
          const SizedBox(height: spacingSm),
          Text('Sin imagen',
              style: TextStyle(color: paleta.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Barra de progreso finita (acumulada).
class BarraProgreso extends StatelessWidget {
  final double valor;
  final Color color;
  final Color fondo;

  const BarraProgreso({
    super.key,
    required this.valor,
    required this.color,
    required this.fondo,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radiusPill),
      child: LinearProgressIndicator(
        value: (valor.clamp(0, 1)).toDouble(),
        minHeight: 8,
        color: color,
        backgroundColor: fondo,
      ),
    );
  }
}