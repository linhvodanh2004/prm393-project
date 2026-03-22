import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/withdrawal_request_model.dart';
import '../../services/withdrawal_service.dart';
import '../../utils/format_utils.dart';

class HostWithdrawalScreen extends StatefulWidget {
  const HostWithdrawalScreen({super.key});

  @override
  State<HostWithdrawalScreen> createState() => _HostWithdrawalScreenState();
}

class _HostWithdrawalScreenState extends State<HostWithdrawalScreen> {
  final _service = WithdrawalService();
  final String? _hostId = FirebaseAuth.instance.currentUser?.uid;

  final _formKey = GlobalKey<FormState>();
  String _bankCode = 'VCB';
  String _bankAccount = '';
  String _accountName = '';
  double _amount = 0;
  bool _submitting = false;

  final _banks = [
    {'code': 'VCB', 'name': 'Vietcombank'},
    {'code': 'TCB', 'name': 'Techcombank'},
    {'code': 'MB', 'name': 'MBBank'},
    {'code': 'ACB', 'name': 'ACB'},
    {'code': 'BIDV', 'name': 'BIDV'},
    {'code': 'VTB', 'name': 'VietinBank'},
    {'code': 'VPB', 'name': 'VPBank'},
  ];

  Future<void> _submitRequest(double availableBalance) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_amount < 50000) {
      _showSnack('Số tiền tối thiểu là 50,000đ', color: Colors.red);
      return;
    }
    if (_amount > availableBalance) {
      _showSnack('Số dư không đủ', color: Colors.red);
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.createRequest(
        hostId: _hostId!,
        amount: _amount,
        bankCode: _bankCode,
        bankAccount: _bankAccount,
        accountName: _accountName,
      );
      if (!mounted) return;
      _showSnack('Tạo yêu cầu rút tiền thành công', color: Colors.green);
      _formKey.currentState!.reset();
      setState(() {
        _amount = 0;
        _bankAccount = '';
        _accountName = '';
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hostId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(child: Text('Vui lòng đăng nhập', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Rút doanh thu', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<double>(
        future: _service.getAvailableBalance(_hostId),
        builder: (context, balanceSnap) {
          if (balanceSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }
          final availableBalance = balanceSnap.data ?? 0.0;

          return StreamBuilder<List<WithdrawalRequestModel>>(
            stream: _service.getRequestsByHost(_hostId),
            builder: (context, requestsSnap) {
              final requests = requestsSnap.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2D2210), Color(0xFF1A1408)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4A853).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text('Số dư khả dụng', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(FormatUtils.vnd(availableBalance),
                              style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Tạo yêu cầu rút tiền',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _bankCode,
                            dropdownColor: const Color(0xFF1A1A1A),
                            decoration: const InputDecoration(
                              labelText: 'Ngân hàng',
                              labelStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Color(0xFF1A1A1A),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.white),
                            items: _banks.map((b) => DropdownMenuItem(
                                value: b['code'],
                                child: Text('${b['code']} - ${b['name']}'))).toList(),
                            onChanged: (val) => setState(() => _bankCode = val!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Số tài khoản',
                              labelStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Color(0xFF1A1A1A),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập số tài khoản' : null,
                            onSaved: (val) => _bankAccount = val!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Tên chủ tài khoản',
                              labelStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Color(0xFF1A1A1A),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.white),
                            textCapitalization: TextCapitalization.characters,
                            validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên tài khoản' : null,
                            onSaved: (val) => _accountName = val!.toUpperCase(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Số tiền rút (VNĐ)',
                              labelStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Color(0xFF1A1A1A),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Vui lòng nhập số tiền';
                              final num = double.tryParse(val);
                                  if (num == null) return 'Số tiền không hợp lệ';
                                  return null;
                                },
                            onSaved: (val) => _amount = double.parse(val!),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : () => _submitRequest(availableBalance),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _submitting
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text('Gửi yêu cầu rút tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Lịch sử rút tiền',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (requests.isEmpty)
                      const Text('Chưa có giao dịch rút tiền nào', style: TextStyle(color: Colors.white54))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final req = requests[index];
                          Color statusColor = Colors.orange;
                          String statusLabel = 'Chờ xử lý';
                          if (req.status == 'approved') {
                            statusColor = Colors.green;
                            statusLabel = 'Thành công';
                          } else if (req.status == 'rejected') {
                            statusColor = Colors.red;
                            statusLabel = 'Từ chối';
                          }

                          return Card(
                            color: const Color(0xFF1A1A1A),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(FormatUtils.vnd(req.amount),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('${req.bankCode} - ${req.bankAccount}\n'
                                  '${FormatUtils.dateTimeVi(req.createdAt)}'
                                  '${req.status == 'rejected' && req.rejectionReason != null ? '\nLý do: ${req.rejectionReason}' : ''}',
                                  style: TextStyle(
                                    color: req.status == 'rejected' ? Colors.redAccent.withOpacity(0.8) : Colors.white54, 
                                    fontSize: 12
                                  )),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.5)),
                                ),
                                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
