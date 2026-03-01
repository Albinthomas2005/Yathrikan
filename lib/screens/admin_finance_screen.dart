import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/constants.dart';
import '../utils/app_localizations.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  DateTime _selectedDate = DateTime.now();

  // Dynamic Data based on the selected date
  late double _totalRevenue;
  late double _growthPercentage;
  late double _currentMonthRevenue;
  late double _lastMonthRevenue;
  late List<double> _chartDataKsrtc;
  late List<double> _chartDataPrivate;
  late List<Map<String, String>> _transactions;

  @override
  void initState() {
    super.initState();
    _generateDataForDate(_selectedDate);
  }

  void _generateDataForDate(DateTime date) {
    // Generate deterministic but pseudo-random data based on the date's hash
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);

    // Baseline values
    const baseRevenue = 5000000.0;
    
    // Revenue logic (growing slightly over time but fluctuating daily)
    _currentMonthRevenue = baseRevenue + random.nextDouble() * 2000000 + (date.month * 100000);
    _lastMonthRevenue = _currentMonthRevenue * (0.85 + random.nextDouble() * 0.2); // Last month is roughly similar
    
    _totalRevenue = _currentMonthRevenue * 12 * (0.9 + random.nextDouble() * 0.2); // Approximated yearly
    
    _growthPercentage = ((_currentMonthRevenue - _lastMonthRevenue) / _lastMonthRevenue) * 100;

    // Charts data (0.2 to 1.0)
    _chartDataKsrtc = List.generate(6, (_) => 0.2 + random.nextDouble() * 0.8);
    _chartDataPrivate = List.generate(6, (_) => 0.2 + random.nextDouble() * 0.8);

    // Transactions list
    final providers = ['KSRTC', 'Private Bus', 'K-SWIFT'];
    _transactions = List.generate(10, (index) {
      final hoursAgo = random.nextInt(24);
      final minsAgo = random.nextInt(60);
      final amount = 50 + random.nextInt(2000);
      
      String timeStr;
      if (hoursAgo == 0) {
        timeStr = '$minsAgo mins ago';
      } else {
        timeStr = '$hoursAgo hrs $minsAgo mins ago';
      }

      return {
        'ticketId': 'BW-${9000 + random.nextInt(1000)}',
        'provider': providers[random.nextInt(providers.length)],
        'time': timeStr,
        'amount': '+₹${NumberFormat('#,##0.00').format(amount)}',
      };
    });
    
    // Sort transactions by 'time' loosely by putting "mins ago" before "hrs ago"
    _transactions.sort((a, b) {
       bool aHrs = a['time']!.contains('hrs');
       bool bHrs = b['time']!.contains('hrs');
       if (aHrs && !bHrs) return 1;
       if (!aHrs && bHrs) return -1;
       return 0; // simplistic sort
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E293B)),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null && date != _selectedDate) {
      setState(() {
        _selectedDate = date;
        _generateDataForDate(date);
      });
    }
  }

  Future<void> _exportReport() async {
    final loc = AppLocalizations.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc['report_exported'],
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );

    final pdf = pw.Document();
    final String dateStr = DateFormat('MMM dd, yyyy').format(_selectedDate);

    // Format currency helper inside the builder scope
    String formatCurrency(double amount) => 'Rs. ${NumberFormat('#,##0.00').format(amount)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Yathrikan Finance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                ]
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Revenue Summary
            pw.Text('Revenue Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Table(
              columnWidths: {
                 0: const pw.FlexColumnWidth(2),
                 1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(children: [pw.Text('Total System Revenue:'), pw.Text(formatCurrency(_totalRevenue), textAlign: pw.TextAlign.right)]),
                pw.TableRow(children: [pw.Text('Current Month:'), pw.Text(formatCurrency(_currentMonthRevenue), textAlign: pw.TextAlign.right)]),
                pw.TableRow(children: [pw.Text('Previous Month:'), pw.Text(formatCurrency(_lastMonthRevenue), textAlign: pw.TextAlign.right)]),
                pw.TableRow(children: [pw.Text('Month-Over-Month Growth:'), pw.Text('${_growthPercentage > 0 ? '+' : ''}${_growthPercentage.toStringAsFixed(2)}%', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: _growthPercentage >= 0 ? PdfColors.green : PdfColors.red))]),
              ]
            ),
            
            pw.SizedBox(height: 30),
            
            // Transactions snippet
            pw.Text('Recent Transactions on $dateStr', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Ticket ID', 'Provider', 'Amount'],
              data: _transactions.take(15).map((t) => [
                t['ticketId']!,
                t['provider']!,
                t['amount']!.replaceAll('₹', 'Rs. ') 
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {2: pw.Alignment.centerRight},
            ),
            
            pw.SizedBox(height: 40),
            pw.Center(
               child: pw.Text('Generated by Yathrikan Admin System', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10))
            )
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Yathrikan_Finance_Report_$dateStr.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isPositiveGrowth = _growthPercentage >= 0;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc['admin_finance_title'],
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryYellow),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Revenue Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc['total_system_revenue'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${NumberFormat('#,##,##0').format(_totalRevenue)}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isPositiveGrowth ? Icons.trending_up : Icons.trending_down,
                          color: isPositiveGrowth ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositiveGrowth ? '+' : ''}${_growthPercentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isPositiveGrowth ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          loc['growth'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc['current_month'],
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.white54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${NumberFormat('#,##,##0').format(_currentMonthRevenue)}',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          Container(
                              width: 1, height: 30, color: Colors.white10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                loc['last_month'],
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.white54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${NumberFormat('#,##,##0').format(_lastMonthRevenue)}',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daily Comparison
              Text(
                loc['daily_comparison'],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _DailyComparisonChart(ksrtcData: _chartDataKsrtc, privateData: _chartDataPrivate),
              ),
              const SizedBox(height: 24),

              // Transaction History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc['transaction_history'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1E293B),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text(
                              loc['all_transactions'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._transactions.map((t) => _TransactionItem(
                              ticketId: t['ticketId']!,
                              provider: t['provider']!,
                              time: t['time']!,
                              amount: t['amount']!,
                            )),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      loc['see_all'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recent Transactions (Show top 3)
              ..._transactions.take(3).map((t) => _TransactionItem(
                ticketId: t['ticketId']!,
                provider: t['provider']!,
                time: t['time']!,
                amount: t['amount']!,
              )),
              
              const SizedBox(height: 16),

              // Export Report Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _exportReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download),
                      const SizedBox(width: 8),
                      Text(
                        loc['export_report'],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_transactions.length > 3)
                _TransactionItem(
                  ticketId: _transactions[3]['ticketId']!,
                  provider: _transactions[3]['provider']!,
                  time: _transactions[3]['time']!,
                  amount: _transactions[3]['amount']!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyComparisonChart extends StatelessWidget {
  final List<double> ksrtcData;
  final List<double> privateData;
  
  const _DailyComparisonChart({
     required this.ksrtcData,
     required this.privateData,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final days = [
      loc['mon'],
      loc['tue'],
      loc['wed'],
      loc['thu'],
      loc['fri'],
      loc['sat']
    ];
    
    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  loc['ksrtc'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF64748B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  loc['private'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Simplified Bar Chart
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(6, (index) {
               return _ChartBar(
                 ksrtcHeight: ksrtcData[index], 
                 privateHeight: privateData[index], 
                 label: days[index]
               );
            }),
          ),
        ),
      ],
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double ksrtcHeight;
  final double privateHeight;
  final String label;

  const _ChartBar({required this.ksrtcHeight, required this.privateHeight, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 12,
              height: 100 * ksrtcHeight,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 100 * privateHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String ticketId;
  final String provider;
  final String time;
  final String amount;

  const _TransactionItem({
    required this.ticketId,
    required this.provider,
    required this.time,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.confirmation_number,
              color: AppColors.primaryYellow,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loc['ticket_id']}: $ticketId',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$provider • $time',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc['success'],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
