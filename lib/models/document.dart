class DocumentModel {
  final String id, imagePath, type, date, personName, providerName,
      documentNumber, amount;
  DocumentModel({required this.id, required this.imagePath, required this.type,
      required this.date, required this.personName, required this.providerName,
      required this.documentNumber, required this.amount});
  Map<String, dynamic> toMap() => {'id': id, 'imagePath': imagePath, 'type': type,
      'date': date, 'personName': personName, 'providerName': providerName,
      'documentNumber': documentNumber, 'amount': amount};
  factory DocumentModel.fromMap(Map m) => DocumentModel(
    id: m['id'] ?? '', imagePath: m['imagePath'] ?? '',
    type: m['type'] ?? 'Other', date: m['date'] ?? 'Not found',
    personName: m['personName'] ?? 'Not found',
    providerName: m['providerName'] ?? 'Not found',
    documentNumber: m['documentNumber'] ?? 'Not found',
    amount: m['amount'] ?? 'Not applicable');
}
