import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/ac.dart';
import '../models/document.dart';
import '../services/storage_service.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel doc;
  final StorageService storage;
  const DocumentDetailScreen({super.key, required this.doc, required this.storage});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _editing = false;
  late final TextEditingController _cName, _cProvider, _cDate, _cAmount, _cDocNo;
  late String _editType;

  @override
  void initState() {
    super.initState();
    _cName = TextEditingController(text: widget.doc.personName);
    _cProvider = TextEditingController(text: widget.doc.providerName);
    _cDate = TextEditingController(text: widget.doc.date);
    _cAmount = TextEditingController(text: widget.doc.amount);
    _cDocNo = TextEditingController(text: widget.doc.documentNumber);
    _editType = widget.doc.type;
  }

  @override
  void dispose() {
    for (var c in [_cName, _cProvider, _cDate, _cAmount, _cDocNo]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final updated = DocumentModel(
      id: widget.doc.id, imagePath: widget.doc.imagePath, type: _editType,
      date: _cDate.text, personName: _cName.text, providerName: _cProvider.text,
      documentNumber: _cDocNo.text, amount: _cAmount.text,
    );
    await widget.storage.saveDocument(updated);
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved'), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final color = AC.forType(_editType);
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: AppBar(
        title: Text(_editing ? 'Edit Document' : 'Details'),
        backgroundColor: AC.header1, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(_editing ? Icons.check : Icons.edit), onPressed: () { if(_editing) _save(); else setState(() => _editing = true); })
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenImage(widget.doc.imagePath))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16), 
              child: Hero(tag: 'docImg', child: Image.file(File(widget.doc.imagePath))),
            ),
          ),
          const SizedBox(height: 16),
          _field('Name', _cName, Icons.person, color),
          _field('Provider', _cProvider, Icons.business, color),
          _field('Date', _cDate, Icons.calendar_today, color),
          _field('Amount', _cAmount, Icons.currency_rupee, color),
          _field('Number', _cDocNo, Icons.tag, color),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AC.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AC.textS)),
          _editing ? TextField(controller: ctrl, decoration: const InputDecoration(isDense: true, border: InputBorder.none)) : Text(ctrl.text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String path;
  const _FullScreenImage(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(tag: 'docImg', child: Image.file(File(path))),
        ),
      ),
    );
  }
}
