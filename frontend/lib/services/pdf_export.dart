import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

class PdfExport {
  static Future<void> exportFatReportPdf(BuildContext context, int fatReportId, int irasasId) async {
    final doc = pw.Document();

    try {
      // fetch metadata
      final fatReports = await Api.fetchFATReports();
      final fatReport = fatReports.cast<Map<String, dynamic>>().firstWhere((r) => (r['id'] ?? r['Id']) == fatReportId, orElse: () => <String, dynamic>{});

      final fatReportIrasai = await Api.fetchFATReportIrasai();
      final fatReportIrasas = fatReportIrasai.cast<Map<String, dynamic>>().firstWhere(
        (f) => ((f['fatreportId'] ?? f['fatReportId'] ?? f['FATReportId'] ?? f['fatreport_id']) == fatReportId) &&
            ((f['irasasId'] ?? f['irasasid'] ?? f['IrasasId']) == irasasId),
        orElse: () => <String, dynamic>{},
      );

      final templates = (await Api.fetchReportTemplates(fatReportId)).cast<Map<String, dynamic>>();

      final rowIrasai = (await Api.fetchRowIrasai()).cast<Map<String, dynamic>>().where((r) => (r['irasasId'] ?? r['irasasid'] ?? r['irasas_id']) == irasasId).toList();
      final rows = (await Api.fetchRows()).cast<Map<String, dynamic>>();

      // Pre-fetch report values and row images (must be awaited before building PDF)
      final Map<int, String> templateValues = {};
      final frId = fatReportIrasas.isEmpty ? null : (fatReportIrasas['id'] ?? fatReportIrasas['Id']);
      if (frId != null) {
        for (final tpl in templates) {
          final tplId = (tpl['id'] ?? tpl['Id']) as int?;
          if (tplId == null) continue;
          try {
            final rv = await Api.fetchReportValueByEverything(frId as int, tplId);
            var valueText = (rv['value'] ?? rv['Value'] ?? '').toString();
            templateValues[tplId] = _formatValueForPdf(valueText);
          } catch (_) {
            templateValues[tplId] = '';
          }
        }
      }

      final Map<int, Uint8List?> rowImageBytes = {};
      final Map<int, List<Map<String, dynamic>>> attachedFilesByRow = {};
      for (final ri in rowIrasai) {
        final rowId = ri['rowId'] ?? ri['rowid'] ?? ri['row_id'];
        if (rowId == null) continue;
        try {
          final files = await Api.fetchPrisegtiFailaiByRow(rowId as int);
          attachedFilesByRow[rowId as int] = files.cast<Map<String, dynamic>>();
          final imageFile = files.cast<Map<String, dynamic>>().firstWhere(
            (f) {
              final name = (f['failoPav'] ?? f['failopav']) as String?;
              return name != null && _isImageFileName(name);
            },
            orElse: () => <String, dynamic>{},
          );
          if (imageFile.isNotEmpty) {
            final id = imageFile['id'] ?? imageFile['Id'];
            final uri = Api.prisegtasFailasFileUri(id.toString());
            final resp = await http.get(uri);
            if (resp.statusCode == 200) {
              rowImageBytes[rowId as int] = resp.bodyBytes;
            } else {
              rowImageBytes[rowId as int] = null;
            }
          } else {
            rowImageBytes[rowId as int] = null;
          }
        } catch (_) {
          rowImageBytes[rowId as int] = null;
          attachedFilesByRow[rowId as int] = <Map<String, dynamic>>[];
        }
      }

      // Fetch additional data required for rendering (avoid await inside PDF build)
      final columnTemplates = (await Api.fetchColumnTemplates()).cast<Map<String, dynamic>>();
      final columnValues = (await Api.fetchColumnValues()).cast<Map<String, dynamic>>();
      final rowValues = (await Api.fetchRowValues()).cast<Map<String, dynamic>>();
      final headers = (await Api.fetchHeaders()).cast<Map<String, dynamic>>();

      // Load a font that contains Lithuanian glyphs and build PDF
      final baseFont = await PdfGoogleFonts.notoSansRegular();

      final baseStyle = pw.TextStyle(font: baseFont);

      // Build PDF
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
          build: (pw.Context ctx) {
            final List<pw.Widget> content = [];

            content.add(pw.Header(
              level: 0,
              child: pw.Text(
                fatReport.isEmpty ? 'FAT ataskaita' : (fatReport['text'] ?? fatReport['Text'] ?? '' ),
                style: baseStyle.copyWith(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ));

            // Report templates and values (pre-fetched)
            if (!fatReportIrasas.isEmpty) {
              content.add(pw.SizedBox(height: 6));
              content.add(pw.Text('Ataskaitos reikšmės:', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold)));

              for (final tpl in templates) {
                final tplId = (tpl['id'] ?? tpl['Id']) as int?;
                final valueText = tplId != null ? (templateValues[tplId] ?? '') : '';
                content.add(pw.Padding(
                    padding: pw.EdgeInsets.only(top: 6, bottom: 6),
                    child: pw.Row(children: [
                      pw.Expanded(child: pw.Text(tpl['text'] ?? tpl['Text'] ?? tpl['description'] ?? tpl['Description'] ?? '', style: baseStyle)),
                      pw.Text(valueText, style: baseStyle),
                    ])));
              }
            }

            content.add(pw.SizedBox(height: 12));
            content.add(pw.Text('Eilutės:', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold)));

            for (var idx = 0; idx < rowIrasai.length; idx++) {
              final ri = rowIrasai[idx];
              final rowIdRaw = ri['rowId'] ?? ri['rowid'] ?? ri['row_id'];
              final rowId = rowIdRaw is int ? rowIdRaw : int.tryParse(rowIdRaw?.toString() ?? '') ?? 0;
              final rowDef = rows.firstWhere((r) => (r['id'] ?? r['Id']) == rowIdRaw, orElse: () => <String, dynamic>{});
              final desc = (rowDef['description'] ?? rowDef['Description'] ?? rowDef['desc'] ?? '').toString();
              final controlMethods = (rowDef['controlMethods'] ?? rowDef['control_methods'] ?? '').toString();

              // Row value
              final rv = rowValues.firstWhere(
                (v) => (v['row_irasas_id'] ?? v['rowIrasasId'] ?? v['RowIrasasId']) == (ri['id'] ?? ri['Id']),
                orElse: () => <String, dynamic>{},
              );
              final rvText = rv.isNotEmpty ? ((rv['value'] ?? rv['Value'] ?? '').toString()) : '';

              // Header table: Row count | row text | control method | row value
              content.add(pw.SizedBox(height: 8));
              content.add(pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Nr', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Eilutė', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Kontrolės metodas', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Eilutės reikšmė', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('${idx + 1}', style: baseStyle)),
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(desc, style: baseStyle)),
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(controlMethods, style: baseStyle)),
                    pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(rvText, style: baseStyle)),
                  ]),
                ],
              ));

              // Columns header space
              final templatesForRow = columnTemplates.where((ct) => (ct['row_id'] ?? ct['rowId'] ?? ct['rowid']) == rowIdRaw).toList()..sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
              if (templatesForRow.isNotEmpty) {
                content.add(pw.SizedBox(height: 6));
                // Columns table: left column label | right column values (single or array)
                content.add(pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
                  columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(5)},
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Stulpelis', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Reikšmė', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                    ]),
                    for (final ct in templatesForRow)
                      () {
                        final header = headers.firstWhere((h) => (h['id'] ?? h['Id']) == (ct['header_id'] ?? ct['headerId'] ?? ct['headerid']), orElse: () => <String, dynamic>{});
                        final headerText = header.isEmpty ? '' : (header['text'] ?? header['Text'] ?? '');
                        final label = (ct['description'] ?? ct['Description'] ?? ct['desc'] ?? '').toString();
                        final colVal = columnValues.firstWhere(
                          (cv) => (cv['row_irasas_id'] ?? cv['rowIrasasId'] ?? cv['RowIrasasId']) == (ri['id'] ?? ri['Id']) &&
                              (cv['column_template_id'] ?? cv['columnTemplateId'] ?? cv['column_template_id']) == (ct['id'] ?? ct['Id']),
                          orElse: () => <String, dynamic>{},
                        );
                        final single = (colVal['single_value'] ?? colVal['singleValue'] ?? colVal['value'])?.toString();
                        final arrayVal = colVal['array_value'] ?? colVal['arrayValue'];
                        final List<String> items = [];
                        if (arrayVal is List) {
                          for (final it in arrayVal) {
                            items.add(it?.toString() ?? '');
                          }
                        } else if (arrayVal is String) {
                          // attempt comma split
                          items.addAll(arrayVal.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
                        }
                        final rightCell = items.isNotEmpty
                          ? pw.Column(children: items.asMap().entries.map((e) {
                            final idx = e.key + 1;
                            final it = e.value;
                            return pw.Padding(
                              padding: pw.EdgeInsets.only(bottom: 4),
                              child: pw.Text('$idx. ${_formatValueForPdf(it)}', style: baseStyle));
                            }).toList())
                          : pw.Text(_formatValueForPdf(single), style: baseStyle);

                        return pw.TableRow(children: [
                          pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(headerText.isNotEmpty ? '$label - $headerText' : label, style: baseStyle)),
                          pw.Padding(padding: pw.EdgeInsets.all(6), child: rightCell),
                        ]);
                      }(),
                  ],
                ));
              }

              // Attached image or file list
              final files = attachedFilesByRow[rowId] ?? <Map<String, dynamic>>[];
              final bytes = rowImageBytes[rowId];
              if (bytes != null) {
                try {
                  final image = pw.MemoryImage(bytes);
                  content.add(pw.SizedBox(height: 8));
                  content.add(pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 0.5)),
                    padding: pw.EdgeInsets.all(6),
                    child: pw.Center(child: pw.Image(image, width: 350)),
                  ));
                } catch (_) {}
              } else if (files.isNotEmpty) {
                content.add(pw.SizedBox(height: 6));
                content.add(pw.Text('Prisegti failai:', style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold)));
                for (final f in files) {
                  final name = (f['failoPav'] ?? f['failopav'] ?? f['fileName'] ?? f['name'])?.toString() ?? '';
                  content.add(pw.Padding(padding: pw.EdgeInsets.only(top: 4), child: pw.Text('- $name', style: baseStyle)));
                }
              }
            }

            return content;
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'fatreport_${fatReportId}_irasas_${irasasId}.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida generuojant PDF: $e')));
      }
    }
  }

  static bool _isImageFileName(String? n) {
    if (n == null) return false;
    final lower = n.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif') || lower.endsWith('.bmp') || lower.endsWith('.webp') || lower.endsWith('.avif') || lower.endsWith('.heic') || lower.endsWith('.heif') || lower.endsWith('.tif') || lower.endsWith('.tiff');
  }

  static String _formatValueForPdf(String? raw) {
    if (raw == null) return '';
    final s = raw.trim();
    if (s.isEmpty) return '';

    try {
      // If value is a JSON array, join and shorten
      if (s.startsWith('[')) {
        final parsed = jsonDecode(s);
        if (parsed is List) {
          final joined = parsed.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).join(', ');
          return _shorten(joined);
        }
      }
    } catch (_) {
      // ignore json errors
    }

    // If it contains commas (likely array-like), shorten
    if (s.contains(',') && s.length > 60) {
      return _shorten(s.replaceAll(RegExp('\n'), ' '));
    }

    return s.length > 120 ? _shorten(s) : s;
  }

  static String _shorten(String s, [int limit = 80]) {
    final one = s.replaceAll(RegExp('\s+'), ' ').trim();
    if (one.length <= limit) return one;
    return '${one.substring(0, limit).trim()}...';
  }
}
