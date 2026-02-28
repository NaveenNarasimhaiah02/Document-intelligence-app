import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/ac.dart';
import '../models/document.dart';
import '../services/storage_service.dart';
import '../services/extraction_service.dart';
import 'detail_screen.dart';
import 'login_screen.dart';
import '../widgets/animated_scanning_logo.dart';
import '../widgets/scanning_overlay.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;
  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _search = TextEditingController();
  final _extraction = ExtractionService();

  List<DocumentModel> _docs = [];
  List<DocumentModel> _filtered = [];
  File? _currentImage;
  String _category = 'All';
  bool _processing = false;
  final Set<String> _selected = {};
  bool get _isSelecting => _selected.isNotEmpty;

  static const _cats = ['All', 'Invoice/Bill', 'Prescription', 'Lab Report', 'ID Proof', 'Insurance', 'Other'];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    _extraction.dispose();
    super.dispose();
  }

  void _load() {
    if (mounted) {
      setState(() {
        _docs = widget.storage.getAllDocuments();
        _filter();
      });
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _docs.where((d) {
        final cat = _category == 'All' || d.type == _category;
        final txt = q.isEmpty ||
            d.personName.toLowerCase().contains(q) ||
            d.providerName.toLowerCase().contains(q) ||
            d.type.toLowerCase().contains(q) ||
            d.documentNumber.toLowerCase().contains(q);
        return cat && txt;
      }).toList();
    });
  }

  Future<void> _pick(ImageSource source) async {
    if (_processing) return;
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _processing = true;
      _currentImage = File(image.path);
    });

    try {
      // Calculate checksum of the picked image
      final checksum = await widget.storage.calculateChecksum(_currentImage!);
      final existing = widget.storage.findDocumentByChecksum(checksum);
      
      if (existing != null) {
        _showError(
          title: 'Duplicate Document',
          message: 'This image has already been scanned.',
          icon: Icons.copy_all_rounded,
        );
        return;
      }

      final permanentPath = await widget.storage.persistImage(_currentImage!);
      final permanentFile = File(permanentPath);

      // Mandatory 2-second delay for the "wow" scanning animation
      await Future.delayed(const Duration(seconds: 2));

      final extracted = await _extraction.processImage(permanentFile);
      if (extracted != null) {
        // Create final doc with checksum
        final doc = DocumentModel(
          id: extracted.id,
          imagePath: extracted.imagePath,
          type: extracted.type,
          date: extracted.date,
          personName: extracted.personName,
          providerName: extracted.providerName,
          documentNumber: extracted.documentNumber,
          amount: extracted.amount,
          checksum: checksum,
        );
        await widget.storage.saveDocument(doc);
        _load();
      } else {
        _showError(
          title: 'Extraction Failed',
          message: 'Could not extract info. Ensure text is clear.',
          icon: Icons.help_outline_rounded,
        );
      }
    } catch (e) {
      _showError(title: 'Processing Failed', message: 'An error occurred during scanning.');
    } finally {
      if (mounted) setState(() { _processing = false; _currentImage = null; });
    }
  }

  void _showError({required String title, required String message, IconData icon = Icons.error_outline_rounded}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(icon, color: Colors.orange, size: 52),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), 
                         style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white),
                         child: const Text('Got it')),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    await widget.storage.deleteDocument(id);
    _selected.remove(id);
    _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _deleteSelected() async {
    final toDelete = _selected.toList();
    setState(() => _processing = true);
    try {
      for (final id in toDelete) {
        await widget.storage.deleteDocument(id);
      }
      setState(() => _selected.clear());
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents deleted'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      _showError(title: 'Delete Failed', message: 'Could not delete all selected items.');
    } finally {
      setState(() => _processing = false);
    }
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AC.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AC.textS.withAlpha(50), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text('Scan Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AC.textP)),
            const SizedBox(height: 24),
            Row(
              children: [
                _PickOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pick(ImageSource.camera);
                  },
                ),
                const SizedBox(width: 16),
                _PickOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pick(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AC.surface,
        title: const Text('Clear All Documents?'),
        content: const Text('This action is permanent and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.storage.clearAll().then((_) => _load());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    final sb = widget.storage.settingsBox;
    final isGuest = sb.get('isGuest', defaultValue: false);
    final email = sb.get('userEmail', defaultValue: '');
    final initial = isGuest ? 'G' : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: AC.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 20),
          CircleAvatar(radius: 30, backgroundColor: AC.header1, child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 24))),
          const SizedBox(height: 12),
          Text(isGuest ? 'Guest User' : email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          if (isGuest)
            ListTile(
              leading: const Icon(Icons.login, color: AC.header1),
              title: const Text('Login / Sign Up', style: TextStyle(color: AC.header1, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen(storage: widget.storage)),
                  (_) => false,
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await widget.storage.settingsBox.put('isLoggedIn', false);
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen(storage: widget.storage)), (_) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Stack(
        children: [
          CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 165, pinned: true, backgroundColor: AC.header1,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [AC.header1, AC.header2])),
                  child: SafeArea(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 10),
                        Row(children: [
                          const AnimatedScanningLogo(size: 44),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('SmartScan', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            Text('Snap. Scan. Done.', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13, letterSpacing: 0.5)),
                          ]),
                          const Spacer(),
                          GestureDetector(onTap: _showProfileSheet, child: const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 20))),
                        ]),
                        const SizedBox(height: 24),
                        Row(children: [
                          _QuickAction(icon: Icons.camera_alt, label: 'Scan', onTap: () => _pick(ImageSource.camera)),
                          const SizedBox(width: 10),
                          _QuickAction(icon: Icons.photo_library, label: 'Gallery', onTap: () => _pick(ImageSource.gallery)),
                          const SizedBox(width: 10),
                          _QuickAction(icon: Icons.search, label: 'Search', onTap: () => FocusScope.of(context).requestFocus(FocusNode())), // Focus search field
                          const SizedBox(width: 10),
                          _QuickAction(icon: Icons.delete_sweep, label: 'Clear All', onTap: _confirmClear),
                        ]),
                    ]),
                  )),
                ),
              ),
            ),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search by name, provider, or type...',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  fillColor: Colors.white,
                ),
              ),
            )),
            SliverToBoxAdapter(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _cats.map((c) => Padding(padding: const EdgeInsets.only(left: 16), child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (s) { if(s) setState(() { _category = c; _filter(); }); }, selectedColor: AC.header2, labelStyle: TextStyle(color: _category == c ? Colors.white : AC.textP, fontWeight: FontWeight.bold)))).toList()))),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  const Text('All Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AC.textP)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(color: AC.header2.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                    child: Text('${_filtered.length}', style: const TextStyle(color: AC.header2, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            )),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final d = _filtered[i];
                  return _DocCard(
                    doc: d, 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(doc: d, storage: widget.storage))).then((_) => _load()),
                    onDelete: () => _delete(d.id),
                    isSelected: _selected.contains(d.id),
                    onLongPress: () => setState(() => _selected.add(d.id)),
                  );
                },
                childCount: _filtered.length,
              )),
            ),
          ]),
          if (_processing && _currentImage != null)
            ScanningOverlay(image: _currentImage!),
        ],
      ),
      bottomNavigationBar: _isSelecting ? Container(
        color: AC.surface, padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(onPressed: _deleteSelected, icon: const Icon(Icons.delete), label: const Text('Delete Selected'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
      ) : null,
      floatingActionButton: _isSelecting ? null : FloatingActionButton(
        onPressed: _showPickSheet,
        backgroundColor: AC.header2,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _PickOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: Colors.white, size: 20), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))]))));
}

class _DocCard extends StatelessWidget {
  final DocumentModel doc; final VoidCallback onTap, onDelete, onLongPress; final bool isSelected;
  const _DocCard({required this.doc, required this.onTap, required this.onDelete, required this.isSelected, required this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final accentColor = AC.forType(doc.type);
    final hasAmount = doc.amount != 'Not applicable';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AC.header2.withAlpha(20) : AC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AC.header2 : Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(isSelected ? 0 : 5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Hero(
                tag: 'doc_${doc.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: File(doc.imagePath).existsSync() 
                    ? Image.file(File(doc.imagePath), width: 85, height: 110, fit: BoxFit.cover) 
                    : Container(width: 85, height: 110, color: AC.bg, child: Icon(AC.iconForType(doc.type), color: accentColor, size: 32)),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Type and Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: accentColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                          child: Text(doc.type, style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 10)),
                        ),
                        Text(doc.date, style: const TextStyle(color: AC.textS, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      doc.providerName != 'Not found' ? doc.providerName : doc.personName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AC.textP, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    // Subtitle details
                    Row(
                      children: [
                        const Icon(Icons.business_center_rounded, size: 12, color: AC.textS),
                        const SizedBox(width: 4),
                        Expanded(child: Text(doc.personName, style: const TextStyle(color: AC.textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bottom Row: Amount and Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hasAmount)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                            child: Text(doc.amount, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12)),
                          )
                        else
                          const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: AC.textS),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
