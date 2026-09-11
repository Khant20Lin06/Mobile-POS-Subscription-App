import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/localization/app_locale.dart';
import '../../inventory/widgets/category_management_dialog.dart';
import '../../subscription/widgets/plan_showcase_dialog.dart';
import '../../subscription/widgets/activation_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/pin_login_dialog.dart';
import '../../auth/widgets/staff_management_dialog.dart';
import '../../auth/widgets/admin_override_dialog.dart';
import '../../../core/database/seeder.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(currentShopProvider);
    final lang = ref.watch(appLanguageProvider);
    final activeUser = ref.watch(currentUserProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);
    final shop = shopAsync.value;
    final isPro = shop?.planTier == 'pro' || shop?.planTier == 'custom';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings, color: Color(0xFF60A5FA), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppTranslations.tr('set_title', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    shop != null ? '${shop.name} (${shop.currency})' : 'DOT POS Engine',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Language Preference Card (EN / MM)
          _buildCard(
            title: AppTranslations.tr('set_language', lang),
            icon: Icons.translate,
            iconColor: const Color(0xFF38BDF8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.my),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: lang == AppLanguage.my ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: lang == AppLanguage.my ? const Color(0xFF60A5FA) : const Color(0xFF334155),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🇲🇲', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'မြန်မာစာ (MM)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: lang == AppLanguage.my ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: lang == AppLanguage.en ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: lang == AppLanguage.en ? const Color(0xFF60A5FA) : const Color(0xFF334155),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'English (EN)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: lang == AppLanguage.en ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Subscription & Plans Showcase Card
          _buildCard(
            title: lang == AppLanguage.my ? 'အသုံးပြုခွင့် လိုင်စင်နှင့် စနစ်များ' : 'Subscription & License',
            icon: Icons.stars,
            iconColor: const Color(0xFFF59E0B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPro ? Icons.stars : Icons.check_circle_outline,
                        color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPro ? 'PRO PLAN (Cloud Sync Active)' : 'FREE PLAN (Offline Standalone)',
                              style: TextStyle(
                                color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPro
                                  ? (lang == AppLanguage.my ? 'ကလောက်ချိတ်ဆက်မှု အောင်မြင်စွာ ပွင့်နေပါသည်' : 'Cloud Sync & Multi-device active')
                                  : (lang == AppLanguage.my ? 'တစ်သက်တာ အခမဲ့ အော့ဖ်လိုင်းသုံးနိုင်ပါသည်' : '100% offline standalone ready'),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.workspace_premium, size: 18),
                        label: Text(
                          AppTranslations.tr('plan_view_all', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () => PlanShowcaseDialog.show(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF60A5FA),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.key, size: 18),
                        label: Text(
                          AppTranslations.tr('plan_activate', lang),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => ActivationDialog.show(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Category CRUD Shortcut Card
          _buildCard(
            title: AppTranslations.tr('inv_manage_categories', lang),
            icon: Icons.category,
            iconColor: const Color(0xFF10B981),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lang == AppLanguage.my
                        ? 'ကုန်ပစ္စည်း အမျိုးအစားများ အသစ်ဖန်တီးခြင်း၊ အရောင်ပြောင်းခြင်းနှင့် စီမံခန့်ခွဲခြင်း'
                        : 'Create, color-code, and organize product categories',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(lang == AppLanguage.my ? 'အမျိုးအစားများ' : 'Categories', style: const TextStyle(fontSize: 12)),
                  onPressed: () => CategoryManagementDialog.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Shop Profile Card
          _buildCard(
            title: AppTranslations.tr('set_shop_profile', lang),
            icon: Icons.store,
            iconColor: const Color(0xFFA855F7),
            child: Column(
              children: [
                _buildInfoRow(lang == AppLanguage.my ? 'ဆိုင်အမည်' : 'Shop Name', shop?.name ?? 'DOT POS Store'),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(lang == AppLanguage.my ? 'အသုံးပြုငွေကြေး' : 'Currency', '${shop?.currency ?? "MMK"} (Myanmar Kyats)'),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(lang == AppLanguage.my ? 'ဘောက်ချာ ပရင်တာ' : 'Printer Width', '58mm / 80mm ESC/POS Thermal'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Cashier PIN & Security Card
          _buildCard(
            title: AppTranslations.tr('set_security', lang),
            icon: Icons.security,
            iconColor: const Color(0xFFEF4444),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.lock, size: 16),
                    label: Text(lang == AppLanguage.my ? 'သော့ခတ်မည်' : 'Lock Screen', style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      ref.read(isTerminalLockedProvider.notifier).state = true;
                      PinLoginDialog.show(context, isLockScreen: true);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.people, size: 16),
                    label: Text(lang == AppLanguage.my ? 'ဝန်ထမ်း PIN စာရင်း' : 'Staff Directory', style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      if (activeUser?.role == 'cashier') {
                        final approved = await AdminOverrideDialog.requestApproval(
                          context,
                          actionTitle: 'Manage Staff Directory',
                        );
                        if (!approved) return;
                      }
                      if (context.mounted) {
                        StaffManagementDialog.show(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Data & Cloud Sync Diagnostics
          _buildCard(
            title: AppTranslations.tr('set_data_cloud', lang),
            icon: Icons.cloud_sync,
            iconColor: const Color(0xFF38BDF8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang == AppLanguage.my ? 'ဆိုင်းငံ့ Sync ဒေတာများ' : 'Pending Sync Queue',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        '${pendingSync.value ?? 0} Pending',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.cloud_upload, size: 16),
                        label: Text(lang == AppLanguage.my ? 'Cloud သိမ်းမည်' : 'Sync to Cloud', style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final syncService = ref.read(syncServiceProvider);
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await syncService.pushPendingChanges();
                          ref.invalidate(pendingSyncCountProvider);
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: result.success ? const Color(0xFF10B981) : Colors.redAccent,
                              content: Text(result.message),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFF334155)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.restart_alt, size: 16),
                        label: Text(lang == AppLanguage.my ? 'Demo ဒေတာထည့်' : 'Reseed Demo', style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await DatabaseSeeder.seedInitialData(ref.read(databaseProvider));
                          ref.invalidate(activeProductsStreamProvider);
                          ref.invalidate(allInventoryProductsStreamProvider);
                          ref.invalidate(categoriesStreamProvider);
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF10B981),
                              content: Text(lang == AppLanguage.my ? 'Demo ဒေတာများ ထည့်သွင်းပြီးပါပြီ' : 'Demo data reseeded successfully!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'DOT POS • Version 1.0.0 (Offline ACID & Cloud Ready)',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
