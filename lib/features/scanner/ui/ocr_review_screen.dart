import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/ocr_document.dart';
import '../scanner_repository.dart';

class OcrReviewArgs {
  const OcrReviewArgs({required this.result, this.imagePath});

  final OcrScanResult result;
  final String? imagePath;
}

class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({super.key, required this.args});

  final OcrReviewArgs args;

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  static const _documentTypes = ['CCF', 'Factura', 'Ticket', 'DTE', 'Otro'];

  final _formKey = GlobalKey<FormState>();
  late String _documentType;
  late final TextEditingController _documentNumberCtrl;
  late final TextEditingController _controlNumberCtrl;
  late final TextEditingController _generationCodeCtrl;
  late final TextEditingController _issuedAtCtrl;
  late final TextEditingController _supplierNameCtrl;
  late final TextEditingController _supplierNitCtrl;
  late final TextEditingController _supplierNrcCtrl;
  late final TextEditingController _supplierActivityCtrl;
  late final TextEditingController _supplierAddressCtrl;
  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _customerNitCtrl;
  late final TextEditingController _customerNrcCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _subtotalCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _confidenceCtrl;
  late final TextEditingController _warningsCtrl;
  late final List<_OcrItemControllers> _items;
  bool _isSaving = false;

  OcrDocumentDraft get _initial => widget.args.result.document;

  @override
  void initState() {
    super.initState();
    final doc = _initial;
    _documentType = _documentTypes.contains(doc.documentType)
        ? doc.documentType
        : 'Otro';
    _documentNumberCtrl = TextEditingController(text: doc.documentNumber ?? '');
    _controlNumberCtrl = TextEditingController(text: doc.controlNumber ?? '');
    _generationCodeCtrl = TextEditingController(text: doc.generationCode ?? '');
    _issuedAtCtrl = TextEditingController(text: doc.issuedAt ?? '');
    _supplierNameCtrl = TextEditingController(text: doc.supplier.name ?? '');
    _supplierNitCtrl = TextEditingController(text: doc.supplier.nit ?? '');
    _supplierNrcCtrl = TextEditingController(text: doc.supplier.nrc ?? '');
    _supplierActivityCtrl = TextEditingController(
      text: doc.supplier.activity ?? '',
    );
    _supplierAddressCtrl = TextEditingController(
      text: doc.supplier.address ?? '',
    );
    _customerNameCtrl = TextEditingController(text: doc.customer.name ?? '');
    _customerNitCtrl = TextEditingController(text: doc.customer.nit ?? '');
    _customerNrcCtrl = TextEditingController(text: doc.customer.nrc ?? '');
    _currencyCtrl = TextEditingController(text: doc.currency);
    _subtotalCtrl = TextEditingController(text: _decimalText(doc.subtotal));
    _taxCtrl = TextEditingController(text: _decimalText(doc.tax));
    _discountCtrl = TextEditingController(text: _decimalText(doc.discount));
    _totalCtrl = TextEditingController(text: _decimalText(doc.total));
    _confidenceCtrl = TextEditingController(text: _decimalText(doc.confidence));
    _warningsCtrl = TextEditingController(text: doc.warnings.join('\n'));
    _items = doc.items.isEmpty
        ? [_OcrItemControllers.empty()]
        : doc.items.map(_OcrItemControllers.fromItem).toList();
  }

  @override
  void dispose() {
    _documentNumberCtrl.dispose();
    _controlNumberCtrl.dispose();
    _generationCodeCtrl.dispose();
    _issuedAtCtrl.dispose();
    _supplierNameCtrl.dispose();
    _supplierNitCtrl.dispose();
    _supplierNrcCtrl.dispose();
    _supplierActivityCtrl.dispose();
    _supplierAddressCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerNitCtrl.dispose();
    _customerNrcCtrl.dispose();
    _currencyCtrl.dispose();
    _subtotalCtrl.dispose();
    _taxCtrl.dispose();
    _discountCtrl.dispose();
    _totalCtrl.dispose();
    _confidenceCtrl.dispose();
    _warningsCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(scannerRepositoryProvider)
          .saveOcrDocument(_buildDocument());
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  OcrDocumentDraft _buildDocument() {
    return OcrDocumentDraft(
      photoReference: _initial.photoReference,
      documentType: _documentType,
      documentNumber: _emptyToNull(_documentNumberCtrl.text),
      controlNumber: _emptyToNull(_controlNumberCtrl.text),
      generationCode: _emptyToNull(_generationCodeCtrl.text),
      issuedAt: _emptyToNull(_issuedAtCtrl.text),
      supplier: OcrParty(
        name: _emptyToNull(_supplierNameCtrl.text),
        nit: _emptyToNull(_supplierNitCtrl.text),
        nrc: _emptyToNull(_supplierNrcCtrl.text),
        activity: _emptyToNull(_supplierActivityCtrl.text),
        address: _emptyToNull(_supplierAddressCtrl.text),
      ),
      customer: OcrParty(
        name: _emptyToNull(_customerNameCtrl.text),
        nit: _emptyToNull(_customerNitCtrl.text),
        nrc: _emptyToNull(_customerNrcCtrl.text),
      ),
      currency: _currencyCtrl.text.trim().isEmpty
          ? 'USD'
          : _currencyCtrl.text.trim().toUpperCase(),
      subtotal: _parseDecimal(_subtotalCtrl.text),
      tax: _parseDecimal(_taxCtrl.text),
      discount: _parseDecimal(_discountCtrl.text),
      total: _parseDecimal(_totalCtrl.text),
      items: _items.map((item) => item.toItem()).toList(),
      confidence: _parseDecimal(_confidenceCtrl.text).clamp(0, 1),
      warnings: _warningsCtrl.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
    );
  }

  void _addItem() {
    setState(() => _items.add(_OcrItemControllers.empty()));
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() => _items.removeAt(index).dispose());
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confidence = (_parseDecimal(_confidenceCtrl.text) * 100)
        .clamp(0, 100)
        .round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar factura'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoStrip(
              confidence: confidence,
              photoName: widget.args.result.photo.originalFilename,
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Documento',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _documentType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de documento',
                    ),
                    items: _documentTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _documentType = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _documentNumberCtrl,
                    label: 'Numero de documento',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _controlNumberCtrl,
                    label: 'Numero de control',
                    icon: Icons.tag_outlined,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _generationCodeCtrl,
                    label: 'Codigo de generacion',
                    icon: Icons.qr_code_2_outlined,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _issuedAtCtrl,
                    label: 'Fecha de emision',
                    icon: Icons.event_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Proveedor',
              child: Column(
                children: [
                  _field(_supplierNameCtrl, label: 'Nombre'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _field(_supplierNitCtrl, label: 'NIT')),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_supplierNrcCtrl, label: 'NRC')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(_supplierActivityCtrl, label: 'Actividad'),
                  const SizedBox(height: 10),
                  _field(_supplierAddressCtrl, label: 'Direccion', maxLines: 2),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Cliente',
              child: Column(
                children: [
                  _field(_customerNameCtrl, label: 'Nombre'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _field(_customerNitCtrl, label: 'NIT')),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_customerNrcCtrl, label: 'NRC')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Totales',
              child: Column(
                children: [
                  _field(
                    _currencyCtrl,
                    label: 'Moneda',
                    textCapitalization: TextCapitalization.characters,
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _decimalField(_subtotalCtrl, label: 'Subtotal'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _decimalField(_taxCtrl, label: 'IVA')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _decimalField(_discountCtrl, label: 'Descuento'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _decimalField(_totalCtrl, label: 'Total'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _decimalField(_confidenceCtrl, label: 'Confianza OCR'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Productos',
              action: IconButton(
                tooltip: 'Agregar item',
                onPressed: _addItem,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    _ItemFields(
                      index: i,
                      item: _items[i],
                      canRemove: _items.length > 1,
                      onRemove: () => _removeItem(i),
                    ),
                    if (i < _items.length - 1) const Divider(height: 24),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Advertencias',
              child: _field(
                _warningsCtrl,
                label: 'Una advertencia por linea',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Guardar lectura',
              icon: Icons.save_outlined,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
    );
  }

  Widget _decimalField(
    TextEditingController controller, {
    required String label,
  }) {
    return _field(
      controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.confidence, this.photoName});

  final int confidence;
  final String? photoName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              photoName == null ? 'Datos extraidos por OCR' : photoName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$confidence%',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemFields extends StatelessWidget {
  const _ItemFields({
    required this.index,
    required this.item,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _OcrItemControllers item;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Item ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Eliminar item',
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        TextFormField(
          controller: item.descriptionCtrl,
          decoration: const InputDecoration(labelText: 'Descripcion'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _itemDecimalField(item.quantityCtrl, 'Cantidad')),
            const SizedBox(width: 10),
            Expanded(child: _itemDecimalField(item.unitPriceCtrl, 'Precio')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _itemDecimalField(item.taxRateCtrl, 'IVA')),
            const SizedBox(width: 10),
            Expanded(child: _itemDecimalField(item.totalCtrl, 'Total')),
          ],
        ),
      ],
    );
  }

  Widget _itemDecimalField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))],
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _OcrItemControllers {
  _OcrItemControllers({
    required this.descriptionCtrl,
    required this.quantityCtrl,
    required this.unitPriceCtrl,
    required this.taxRateCtrl,
    required this.totalCtrl,
  });

  factory _OcrItemControllers.fromItem(OcrDocumentItem item) {
    return _OcrItemControllers(
      descriptionCtrl: TextEditingController(text: item.description ?? ''),
      quantityCtrl: TextEditingController(text: _decimalText(item.quantity)),
      unitPriceCtrl: TextEditingController(text: _decimalText(item.unitPrice)),
      taxRateCtrl: TextEditingController(text: _decimalText(item.taxRate)),
      totalCtrl: TextEditingController(text: _decimalText(item.total)),
    );
  }

  factory _OcrItemControllers.empty() {
    return _OcrItemControllers(
      descriptionCtrl: TextEditingController(),
      quantityCtrl: TextEditingController(text: '0'),
      unitPriceCtrl: TextEditingController(text: '0'),
      taxRateCtrl: TextEditingController(text: '0.13'),
      totalCtrl: TextEditingController(text: '0'),
    );
  }

  final TextEditingController descriptionCtrl;
  final TextEditingController quantityCtrl;
  final TextEditingController unitPriceCtrl;
  final TextEditingController taxRateCtrl;
  final TextEditingController totalCtrl;

  OcrDocumentItem toItem() {
    return OcrDocumentItem(
      description: _emptyToNull(descriptionCtrl.text),
      quantity: _parseDecimal(quantityCtrl.text),
      unitPrice: _parseDecimal(unitPriceCtrl.text),
      taxRate: _parseDecimal(taxRateCtrl.text),
      total: _parseDecimal(totalCtrl.text),
    );
  }

  void dispose() {
    descriptionCtrl.dispose();
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
    taxRateCtrl.dispose();
    totalCtrl.dispose();
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Campo requerido';
  return null;
}

String? _emptyToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

double _parseDecimal(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}

String _decimalText(double value) {
  final fixed = value.toStringAsFixed(4);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
