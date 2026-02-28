import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/document.dart';

class ExtractionService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<DocumentModel?> processImage(File img) async {
    try {
      final inputImage = InputImage.fromFile(img);
      final recognizedText = await _recognizer.processImage(inputImage);
      final text = recognizedText.text.toUpperCase();
      final lines = text.split('\n');

      // Guard: unreadable image
      final wordCount = text.trim().split(RegExp(r'\s+')).where((w) => w.length > 1).length;
      if (text.trim().length < 20 || wordCount < 3) return null;

      final type = _classifyDocument(text);
      final date = _extractDate(text);
      final name = _extractName(lines, type, recognizedText);
      final docNo = _extractDocNumber(text);
      final amount = _extractAmount(lines, type);
      final provider = _extractProvider(lines, type, text, recognizedText, name);

      return DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: img.path,
        type: type,
        date: date,
        personName: name,
        providerName: provider,
        documentNumber: docNo,
        amount: amount,
      );
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _recognizer.close();
  }

  String _extractDate(String text) {
    for (final p in [
      RegExp(r'(?:DATE|DOB|BIRTH)[^\d]*(\d{2}[\/\-]\d{2}[\/\-]\d{4})'),
      RegExp(r'\b(\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{4}[\/\-]\d{2}[\/\-]\d{2})\b'),
      RegExp(r'\b(\d{1,2}\s+(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\w*\s+\d{4})\b'),
      RegExp(r'\b((?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\w*\s+\d{1,2},?\s+\d{4})\b'),
    ]) {
      final m = p.firstMatch(text);
      if (m != null) return (m.group(1) ?? m.group(0))!;
    }
    return 'Not found';
  }

  String _classifyDocument(String text) {
    if (text.contains('AADHAAR') || text.contains('UNIQUE IDENTIFICATION') ||
        text.contains('VOTER ID') || text.contains('ELECTOR PHOTO') || 
        text.contains('ELECTION COMMISSION') || text.contains('निर्वाचन आयोग') ||
        text.contains('DRIVING LICENCE') || text.contains('PERMANENT ACCOUNT NUMBER') ||
        text.contains('INCOME TAX DEPARTMENT') || text.contains('PASSPORT') ||
        text.contains('GOVERNMENT OF INDIA') || text.contains('GOVT OF INDIA') || 
        text.contains('भारत सरकार') || text.contains('आधार')) {
      return 'ID Proof';
    } else if (text.contains('POLICYHOLDER') || text.contains('POLICY SCHEDULE') ||
        text.contains('PREMIUM') || text.contains('INSURED') || text.contains('COVERAGE')) {
      return 'Insurance';
    } else if (text.contains('PRESCRIPTION') || text.contains('DOSAGE') ||
        (text.contains('TABLET') && text.contains('MG'))) {
      return 'Prescription';
    } else if (text.contains('LAB REPORT') || text.contains('PATHOLOGY') ||
        text.contains('TEST RESULT') || (text.contains('LAB') && text.contains('RESULT')) ||
        text.contains('HEMOGLOBIN') || text.contains('HAEMOGLOBIN') ||
        text.contains('RBC') || text.contains('CBC') || text.contains('HAEMATOLOGY') ||
        text.contains('BLOOD COUNT') || text.contains('LEUKOCYTE') ||
        text.contains('LABORATORY') || text.contains('TEST REPORT')) {
      return 'Lab Report';
    } else if (text.contains('TAX INVOICE') || text.contains('GST') ||
        text.contains('INVOICE') || text.contains('RECEIPT') || text.contains('TOTAL') ||
        text.contains('GRAND TOTAL') || text.contains('PRICE') || text.contains('QTY') || 
        text.contains('ITEM') || text.contains('SOLD BY') || text.contains('ORDER NUMBER') ||
        text.contains('BILLING ADDRESS') || text.contains('RETAIL INVOICE')) {
      return 'Invoice/Bill';
    }
    return 'Other';
  }

  String _extractName(List<String> lines, String type, RecognizedText recognizedText) {
    final excludeKeywords = [
      'FATHER', 'MOTHER', 'HUSBAND', 'GUARDIAN', 'WIFE', 'S/O', 'D/O', 'W/O', 'S/W/D',
      'SON OF', 'DAUGHTER OF', 'WIFE OF', 'SIGNATURE', 'AUTHORITY', 'AUTHORISATION',
      'ADDRESS', 'DEPARTMENT', 'MINISTRY', 'ELECTION', 'COMMISSION',
      'INDIA', 'GOVERNMENT', 'UNIQUE', 'IDENTIFICATION', 'INCOME', 'TAX',
      'ACCOUNT', 'NUMBER', 'PERMANENT', 'ISSUING', 'VALIDITY', 'DATE OF ISSUE', 'ISSUE DATE',
      'IDENTITY CARD', 'DETAILS', 'ELECTOR', 'EPIC', 'ASSEMBLY', 'CONSTITUENCY',
      'DATE OF BIRTH', 'BIRTH', 'DOB', '出生日期', 'GENDER', 'SEX', 'MALE', 'FEMALE',
      'नाम', 'निर्वाचक', 'पिता', 'पति', 'लिंग', 'पता', 'পিতার', 'আয়কর', 'জন্ম', 'तिथि',
      'ORGAN', 'DONOR', 'BLOOD', 'GROUP', 'LICENCE', 'STATE', 'KERALA', 'ISSUED BY', 
      'HOLDER', 'NOT VALID', 'TRANSPORT', 'INV CARR', 'ISSUE', 'VALID', 'DATE', 'DELHI'
    ].map((e) => e.toUpperCase()).toList();

    if (type == 'Lab Report') return 'Not found';

    if (type == 'ID Proof') {
      final text = recognizedText.text.toUpperCase();
      
      // Special Logic for PAN Cards (Income Tax Dept)
      if (text.contains('INCOME TAX') || text.contains('আয়কর')) {
         final candidates = <String>[];
         for (final block in recognizedText.blocks) {
           for (final line in block.lines) {
             final val = line.text.trim();
             if (_isValidName(val, excludeKeywords) && val.split(' ').length >= 2) {
               candidates.add(val);
             }
           }
         }
         if (candidates.isNotEmpty) return candidates.first;
      }

      final nameLabels = [
        'ELECTOR\'S NAME', 'HOLDER\'S NAME', 'GIVEN NAME', 
        'नाम', 'নাম', 'निर्वाचक का नाम', 'নির্বাচকের নাম', 'नाम / NAME', 'নাম / NAME',
        'NAME', 'नाम', 'নাম'
      ];

      // Priority 1: Labeled Names (Multi-lingual & Location aware)
      for (final block in recognizedText.blocks) {
        for (int i = 0; i < block.lines.length; i++) {
          final ln = block.lines[i].text.trim();
          final upperLn = ln.toUpperCase();
          
          for (final label in nameLabels) {
            if (upperLn.contains(label.toUpperCase())) {
              // Case 1: Name is on the same line
              // Find the end of the label and take everything after it
              int labelIdx = upperLn.indexOf(label.toUpperCase());
              String remainder = ln.substring(labelIdx + label.length).trim();
              
              // Clean leading colons, hyphens, slashes
              remainder = remainder.replaceFirst(RegExp(r'^[:\-\/\s\.]+'), '').trim();
              
              if (_isValidName(remainder, excludeKeywords)) return remainder;

              // Case 2: Name is on the line below the label
              if (i + 1 < block.lines.length) {
                String below = block.lines[i+1].text.trim();
                below = below.replaceFirst(RegExp(r'^[:\-\/\s\.]+'), '').trim();
                if (_isValidName(below, excludeKeywords)) return below;
              }
            }
          }
        }
      }

      // Priority 2: Pattern-based extraction (e.g., Aadhaar style - line above DOB)
      for (int i = 0; i < lines.length; i++) {
        final ln = lines[i].trim().toUpperCase();
        if (ln.contains('DOB') || ln.contains('DATE OF BIRTH') || ln.contains('BIRTH') || ln.contains('जन्म तारीख') || ln.contains('जन्म तिथि')) {
          for (int j = 1; j <= 2; j++) {
             if (i - j >= 0) {
               final candidate = lines[i-j].trim();
               // Require multi-word and NO digits for ID names
               if (_isValidName(candidate, excludeKeywords) && candidate.split(' ').length >= 2 && !RegExp(r'\d').hasMatch(candidate)) {
                 return candidate;
               }
             }
          }
        }
      }
    } else {
      // Strict extraction for other types: ONLY if labeled
      final labeledNameLabels = type == 'Prescription' 
        ? ['PATIENT NAME', 'PATIENT', 'NAME'] 
        : ['NAME', 'PATIENT', 'HOLDER', 'CUSTOMER', 'CLIENT'];
      
      for (final ln in lines.take(15)) {
        final upper = ln.toUpperCase();
        for (final label in labeledNameLabels) {
          if (upper.contains(label)) {
            final parts = ln.split(RegExp(r'[:\-]'));
            if (parts.length > 1) {
              final val = parts.last.trim();
              if (_isValidName(val, excludeKeywords) && !RegExp(r'\d').hasMatch(val)) return val;
            }
          }
        }
      }
      return 'Not found'; // Return Not found instead of falling back to random lines
    }

    // Default: Return the first multi-word line that looks like a name (only for IDs if priority failed)
    if (type == 'ID Proof') {
      for (final ln in lines.take(15)) {
        if (_isValidName(ln, excludeKeywords) && ln.trim().split(' ').length >= 2 && !RegExp(r'\d').hasMatch(ln)) return ln.trim();
      }
    }

    return 'Not found';
  }

  bool _isValidName(String s, List<String> exclude) {
    if (s.isEmpty || s.length < 3) return false;
    final u = s.toUpperCase();
    if (!RegExp(r'[A-Za-z\u0980-\u09FF\u0900-\u097F]').hasMatch(s)) return false;
    // Strict no-digits rule for names
    if (RegExp(r'\d').hasMatch(s)) return false;
    for (final ex in exclude) {
      if (u.contains(ex)) return false;
    }
    if (s.length > 40) return false;
    return true;
  }

  String _extractDocNumber(String text) {
    // Aadhaar Number (12 digits, often separated by space)
    final aadhaarM = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b').firstMatch(text);
    if (aadhaarM != null) return aadhaarM.group(0)!;

    final panM = RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b').firstMatch(text);
    if (panM != null) return panM.group(0)!;

    // Voter ID / EPIC Number (Handle KKD1933993 style)
    final epicM = RegExp(r'\b[A-Z]{3}\d{7}\b', caseSensitive: false).firstMatch(text);
    if (epicM != null) return epicM.group(0)!;

    // Driving Licence (Supports: SS RR YYYY NNNNNNN, SS-RR-YYYY-NNNNNNN, etc.)
    final dlM = RegExp(r'\b[A-Z]{2}[-\s]?[0-9]{2}[-\s]?(?:19|20)[0-9]{2}[-\s]?[0-9]{7,11}\b', caseSensitive: false).firstMatch(text);
    if (dlM != null) return dlM.group(0)!;

    final refM = RegExp(r'(?:INVOICE|BILL|RECEIPT|POLICY|TRANSACTION|EPIC|ELECTOR|DL|DRIVING|LICENCE)\s+(?:NO|NUMBER|ID)\s*[:\-#]?\s*([A-Z0-9][A-Z0-9\-\/]{3,})', caseSensitive: false).firstMatch(text);
    if (refM != null) return refM.group(1)!;

    return 'Not found';
  }

  String _extractAmount(List<String> lines, String type) {
    if (type != 'Invoice/Bill') return 'Not applicable';

    final List<Map<String, dynamic>> amountCandidates = [];
    // Pattern to match common price formats: optionally with prefixes like TOTAL or RS.
    final amountPat = RegExp(r'(?:RS\.?\s*|₹\s*|INR\s*|TOTAL\s*|AMOUNT\s*|BILL\s*)?(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?|\d{1,10}(?:\.\d{1,2})?)', caseSensitive: false);
    // Standalone numbers at the end of lines (e.g., in a table or total section)
    final standalonePat = RegExp(r'\s+(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2}))(?:\s*)$');

    // Keywords for hierarchy (Level 1: Grand Total, Level 2: General Total)
    final superPriorityKeywords = ['GRAND TOTAL', 'TOTAL BILL', 'TOTAL AMOUNT', 'NET PAYABLE', 'AMOUNT PAID', 'NET AMOUNT PAID', 'TOTAL PAYABLE'];
    final priorityKeywords = ['TOTAL', 'BILL', 'NET', 'PAID', 'AMOUNT'];

    // Keywords to ignore lines containing discounts, savings, IDs, or quantities
    final discardKeywords = [
      'SAVED', 'SAVE', 'DISCOUNT', 'OFF', 'PROMO', 'VOUCHER', 'LESS', 'COUPON', 'CASHBACK', 'FREE',
      'QTY', 'QUANTITY', 'ITEMS:', 'ITEM', 'BILL NO', 'ORDER NO', 'TICKET NO', 'TXN ID', 'INV NO', 
      'GSTIN', 'DATE:', 'PHONE', 'MOBILE', 'ID:'
    ];

    for (final ln in lines) {
      final upperLn = ln.toUpperCase();
      
      // Skip lines that indicate savings or discounts
      bool shouldSkip = false;
      for (final kw in discardKeywords) {
        if (upperLn.contains(kw)) {
          shouldSkip = true;
          break;
        }
      }
      if (shouldSkip) continue;

      int priorityLevel = 0; // 0: Normal, 1: Priority, 2: Super Priority
      for (final kw in superPriorityKeywords) {
        if (upperLn.contains(kw)) {
          priorityLevel = 2;
          break;
        }
      }
      if (priorityLevel == 0) {
        for (final kw in priorityKeywords) {
          if (upperLn.contains(kw)) {
            priorityLevel = 1;
            break;
          }
        }
      }

      // Find matches from main pattern
      final List<Map<String, dynamic>> lineCandidates = [];
      for (final m in amountPat.allMatches(ln)) {
        String matchStr = m.group(1)!;
        final rawVal = matchStr.replaceAll(',', '');
        final val = double.tryParse(rawVal);
        
        if (val != null && val > 0 && val < 10000000) {
          // Rule: If no currency prefix and no decimal point, it's likely not an amount
          bool hasPrefix = ln.substring(0, m.start).toUpperCase().contains(RegExp(r'RS|₹|INR|TOTAL|BILL|AMOUNT|NET|GRAND|PAID'));
          bool hasDecimal = matchStr.contains('.');
          
          if (!hasPrefix && !hasDecimal) continue;
          if (val < 100 && !hasPrefix && !hasDecimal) continue;

          lineCandidates.add({'val': val, 'priority': priorityLevel});
        }
      }

      // If multiple candidates on the same line and it's a priority line, favoring the LAST one (strikethrough logic)
      if (lineCandidates.length > 1 && priorityLevel > 0) {
        amountCandidates.add(lineCandidates.last);
      } else {
        amountCandidates.addAll(lineCandidates);
      }
      
      // Standalone pattern if no matches yet
      if (lineCandidates.isEmpty) {
        final sm = standalonePat.firstMatch(ln);
        if (sm != null) {
          final val = double.tryParse(sm.group(1)!.replaceAll(',', ''));
          if (val != null && val > 0 && val < 10000000) {
             amountCandidates.add({'val': val, 'priority': priorityLevel});
          }
        }
      }
    }

    if (amountCandidates.isEmpty) return 'Not applicable';

    // Tiered selection:
    // 1. Check Super Priority (Level 2)
    // 2. Check Priority (Level 1)
    // 3. Normal
    
    final superMatches = amountCandidates.where((c) => c['priority'] == 2).toList();
    final priorityMatches = amountCandidates.where((c) => c['priority'] == 1).toList();
    
    double finalAmt;
    if (superMatches.isNotEmpty) {
      superMatches.sort((a, b) => (b['val'] as double).compareTo(a['val'] as double));
      finalAmt = superMatches.first['val'];
    } else if (priorityMatches.isNotEmpty) {
      priorityMatches.sort((a, b) => (b['val'] as double).compareTo(a['val'] as double));
      finalAmt = priorityMatches.first['val'];
    } else {
      amountCandidates.sort((a, b) => (b['val'] as double).compareTo(a['val'] as double));
      finalAmt = amountCandidates.first['val'];
    }

    return 'Rs.${finalAmt.toStringAsFixed(2)}';
  }

  String _extractProvider(List<String> lines, String type, String text, RecognizedText recognizedText, String personName) {
    TextLine? bestLine;
    double maxScore = -1.0;
    final upperPersonName = personName.toUpperCase();

    final excludeHeaders = [
      'IDENTITY CARD', 'ELECTION COMMISSION', 'NAME', 'DOB', 'SEX', 'MALE', 'FEMALE',
      'GRAND TOTAL', 'SUB TOTAL', 'TOTAL QTY', 'THANK YOU', 'VISIT AGAIN', 'PRICE', 
      'AMOUNT', 'ITEM', 'QTY', 'RATE', 'TAX', 'INVOICE', 'CUSTOMER CARE', 'WEBSITE', 
      'EMAIL', 'ORDER', 'TAB', 'TABLE', 'BILL', 'ELECTOR PHOTO IDENTITY', 'PCS', 'KG', 'GM'
    ];

    // Find approximate document height to normalize positions
    double docHeight = 0;
    for (final block in recognizedText.blocks) {
       if (block.boundingBox.bottom > docHeight) docHeight = block.boundingBox.bottom;
    }

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final txt = line.text.trim().toUpperCase();
        if (txt.length < 3) continue;
        
        // Skip if it contains any digits (User Instruction: No digits in provider name)
        if (RegExp(r'\d').hasMatch(txt)) continue;

        // Skip lines that look like product items (contains units or multiple numbers)
        if (txt.contains(RegExp(r'\d+\s*(?:PCS?|KG|GM|L|ML|PKT|PC)'))) continue;
        if (RegExp(r'\d+.*\d+').hasMatch(txt)) continue; // Multiple numbers likely Price/Qty

        // Skip if this is the person's name we already extracted
        if (txt == upperPersonName || upperPersonName.contains(txt)) continue;
        
        bool shouldExclude = false;
        for (final ex in excludeHeaders) {
          if (txt == ex || txt.contains(ex)) { shouldExclude = true; break; }
        }
        if (shouldExclude) continue;

        final height = line.boundingBox.height;
        final top = line.boundingBox.top;
        
        // Universal Priority: MUST be in the top part of the document
        final relativeTop = docHeight > 0 ? top / docHeight : 0.5;
        if (relativeTop > 0.22) continue; // Tighter cutoff: Provider name must be in the top 22%

        // Non-linear scoring: font size (height) is squared to exponentially favor larger text
        double score = height * height; 
        
        // Boost for being very close to the top
        if (relativeTop < 0.12) {
          score *= 8.0;
        } else if (relativeTop < 0.25) {
          score *= 3.0;
        }

        // Voter ID Provider Boost for "Election Commission"
        if (type == 'ID Proof' && (txt.contains('ELECTION') || txt.contains('COMMISSION'))) {
           score *= 5.0;
        }

        if (score > maxScore) {
          maxScore = score;
          bestLine = line;
        }
      }
    }

    if (bestLine != null && maxScore > 2) {
      return bestLine.text.trim();
    }

    // Fallback logic
    if (text.contains('AADHAAR') || text.contains('आधार')) return 'Government of India (Aadhaar)';
    if (text.contains('ELECTION COMMISSION')) return 'Election Commission of India';
    if (text.contains('DRIVING LICENCE')) return 'Transport Department';
    if (text.contains('INCOME TAX DEPARTMENT')) return 'Income Tax Department';
    
    if (type == 'Invoice/Bill') {
      for (final ln in lines.take(5)) {
        if (ln.length > 4 && !ln.contains('INVOICE') && !ln.contains('TAX') && !ln.contains('BILL')) return ln.trim();
      }
    }
    return 'Not found';
  }
}
