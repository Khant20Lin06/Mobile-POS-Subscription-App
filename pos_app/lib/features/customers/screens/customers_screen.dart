import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/customer_statement_dialog.dart';
import '../widgets/debt_repayment_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _filterDebtOnly = false;

  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Customer', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove "${customer.name}" from your customer directory?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(customerDaoProvider).softDeleteCustomer(customer.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFEF4444),
                    content: Text('Customer "${customer.name}" removed.'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _generateAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'C';
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.people_alt, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Customers & Debt Ledger',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => CustomerFormDialog.show(context),
              icon: const Icon(Icons.person_add_alt, size: 16),
              label: const Text('+ Customer', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (allCustomers) {
          // Filter Customers
          final filteredCustomers = allCustomers.where((c) {
            final matchesSearch = _searchQuery.isEmpty ||
                c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (c.phone?.contains(_searchQuery) ?? false);
            final matchesDebt = !_filterDebtOnly || c.totalDebt > 0;
            return matchesSearch && matchesDebt;
          }).toList();

          // Calculate Totals
          double totalMarketDebt = 0.0;
          int customersWithDebtCount = 0;

          for (final c in allCustomers) {
            if (c.totalDebt > 0) {
              totalMarketDebt += c.totalDebt;
              customersWithDebtCount++;
            }
          }

          return Column(
            children: [
              // Top KPI Summary Cards (Horizontally Scrollable for Mobile)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildKpiCard(
                        title: 'Total Customers',
                        value: '${allCustomers.length}',
                        subtitle: 'Active profiles',
                        icon: Icons.people_outline,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        title: 'Active Debtors',
                        value: '$customersWithDebtCount',
                        subtitle: 'Have unpaid balance',
                        icon: Icons.assignment_late_outlined,
                        color: customersWithDebtCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        title: 'Total Market Debt',
                        value: '${_currencyFormat.format(totalMarketDebt)} MMK',
                        subtitle: 'Outstanding to collect',
                        icon: Icons.account_balance_wallet_outlined,
                        color: totalMarketDebt > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),

              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Search Input
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search customer by name or phone...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Filter Chip
                    FilterChip(
                      selected: _filterDebtOnly,
                      label: Text(
                        'With Debt ($customersWithDebtCount)',
                        style: TextStyle(
                          color: _filterDebtOnly ? Colors.white : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: _filterDebtOnly ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      side: BorderSide(
                        color: _filterDebtOnly ? const Color(0xFFEF4444) : const Color(0xFF334155),
                      ),
                      onSelected: (val) => setState(() => _filterDebtOnly = val),
                    ),
                  ],
                ),
              ),

              // Customer List
              Expanded(
                child: filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final customer = filteredCustomers[index];
                          return _buildCustomerCard(customer);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
        error: (err, _) => Center(child: Text('Error loading customers: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            subtitle,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final hasDebt = customer.totalDebt > 0;
    final avatarColor = _generateAvatarColor(customer.name);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDebt ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF334155),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Name/Phone + Debt Badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: avatarColor.withValues(alpha: 0.2),
                      child: Text(
                        _getInitials(customer.name),
                        style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 11, color: customer.phone != null ? const Color(0xFF64748B) : Colors.transparent),
                              const SizedBox(width: 4),
                              Text(
                                customer.phone ?? 'No phone',
                                style: TextStyle(
                                  color: customer.phone != null ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasDebt ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasDebt ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_currencyFormat.format(customer.totalDebt)} MMK',
                            style: TextStyle(
                              color: hasDebt ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            hasDebt ? 'Debt Due' : 'No Debt',
                            style: TextStyle(
                              color: hasDebt ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 4),

                // Bottom Row: Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (hasDebt)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                            foregroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.payments_outlined, size: 15),
                          label: const Text('Repay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => DebtRepaymentDialog.show(context, customer),
                        ),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Statement',
                      icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF38BDF8), size: 18),
                      onPressed: () => CustomerStatementDialog.show(context, customer),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 18),
                      onPressed: () => CustomerFormDialog.show(context, customerToEdit: customer),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                      onPressed: () => _confirmDeleteCustomer(customer),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Wide layout
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasDebt ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF334155),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withValues(alpha: 0.2),
                child: Text(
                  _getInitials(customer.name),
                  style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: customer.phone != null ? const Color(0xFF64748B) : Colors.transparent),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone ?? 'No phone',
                          style: TextStyle(
                            color: customer.phone != null ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hasDebt ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasDebt ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_currencyFormat.format(customer.totalDebt)} MMK',
                      style: TextStyle(
                        color: hasDebt ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      hasDebt ? 'Debt Outstanding' : 'No Debt',
                      style: TextStyle(
                        color: hasDebt ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasDebt)
                    IconButton(
                      tooltip: 'Repay Debt (အကြွေးဆပ်ရန်)',
                      icon: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 22),
                      onPressed: () => DebtRepaymentDialog.show(context, customer),
                    ),
                  IconButton(
                    tooltip: 'Account Statement (စာရင်းမှတ်တမ်း)',
                    icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF38BDF8), size: 20),
                    onPressed: () => CustomerStatementDialog.show(context, customer),
                  ),
                  IconButton(
                    tooltip: 'Edit Profile',
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () => CustomerFormDialog.show(context, customerToEdit: customer),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                    onPressed: () => _confirmDeleteCustomer(customer),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(Icons.people_outline, size: 48, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Customers Found',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add customer profiles to start tracking credit and repayments.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => CustomerFormDialog.show(context),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add New Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
