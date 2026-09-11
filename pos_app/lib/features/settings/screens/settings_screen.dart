import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
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
import '../widgets/shop_profile_dialog.dart';
import '../widgets/printer_settings_dialog.dart';
import '../widgets/scan_gun_settings_dialog.dart';
import '../widgets/backup_restore_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
                _buildInfoRow(lang == AppLanguage.my ? 'ဖုန်းနံပါတ်' : 'Phone', shop?.phone ?? '09-770001122'),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(lang == AppLanguage.my ? 'ဆိုင်လိပ်စာ' : 'Address', shop?.address ?? 'No. 123, Bogyoke Road, Yangon'),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(lang == AppLanguage.my ? 'အသုံးပြုငွေကြေး' : 'Currency', '${shop?.currency ?? "MMK"} (Myanmar Kyats)'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA855F7),
                    side: const BorderSide(color: Color(0xFFA855F7)),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(
                    lang == AppLanguage.my ? 'ဆိုင်အချက်အလက် ပြင်ဆင်မည်' : 'Edit Shop Profile',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: shop == null ? null : () => ShopProfileDialog.show(context, shop),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Thermal Printer Setup Card
          _buildCard(
            title: AppTranslations.tr('set_printer', lang),
            icon: Icons.print,
            iconColor: const Color(0xFF38BDF8),
            child: Column(
              children: [
                _buildInfoRow(lang == AppLanguage.my ? 'ပရင်တာ အခြေအနေ' : 'Printer Status', 'Ready (ESC/POS)'),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(lang == AppLanguage.my ? 'ချိတ်ဆက်မှု စနစ်' : 'Interface', 'Bluetooth / WiFi / USB'),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(lang == AppLanguage.my ? 'ဘောက်ချာ အရွယ်အစား' : 'Paper Size', '58mm / 80mm Thermal'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.settings, size: 16),
                  label: Text(
                    lang == AppLanguage.my ? 'ပရင်တာ ချိတ်ဆက်မှု ဆက်တင် / Test Print' : 'Configure Printer & Test Print',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => PrinterSettingsDialog.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Barcode Scan Gun Setup Card
          _buildCard(
            title: lang == AppLanguage.my ? 'ဘားကုဒ် စကန်ဖတ်စက် ဆက်တင်' : 'Barcode Scan Gun & Hardware',
            icon: Icons.qr_code_scanner,
            iconColor: const Color(0xFF10B981),
            child: Column(
              children: [
                _buildInfoRow(
                  lang == AppLanguage.my ? 'စကန်ဖတ်စက် အခြေအနေ' : 'Scanner Status',
                  'Active (Plug & Play)',
                ),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(
                  lang == AppLanguage.my ? 'ချိတ်ဆက်မှု အမျိုးအစား' : 'Supported Modes',
                  'USB Laser / Bluetooth / Camera',
                ),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(
                  lang == AppLanguage.my ? 'အလိုအလျောက် ပစ္စည်းထည့်' : 'Auto Add to Cart',
                  'Enabled (Instant Match)',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(
                    lang == AppLanguage.my ? 'စကန်ဖတ်စက် ဆက်တင် / Test Scan' : 'Configure Scan Gun & Live Test',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => ScanGunSettingsDialog.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 7. Cashier PIN & Security Card (Admin Edit Enabled)
          _buildCard(
            title: AppTranslations.tr('set_security', lang),
            icon: Icons.security,
            iconColor: const Color(0xFFEF4444),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF59E0B),
                        child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeUser != null && activeUser.role == 'owner' ? '${activeUser.name} (Admin)' : 'Administrator (Owner)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              lang == AppLanguage.my ? 'အက်ဒမင် PIN ဖြင့် ဆက်တင်နှင့် အခွင့်အရေးများ ထိန်းချုပ်နိုင်သည်' : 'Full access & administrative override PIN',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: Text(
                          lang == AppLanguage.my ? 'PIN ပြင်မည်' : 'Edit PIN',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _handleEditAdmin(context, ref, lang),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
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
          const SizedBox(height: 16),

          // 9. Excel & JSON Data Backup Card
          _buildCard(
            title: lang == AppLanguage.my ? 'ဒေတာ Backup & Excel ထုတ်ယူခြင်း' : 'Data Backup & Excel / JSON Export',
            icon: Icons.backup_table,
            iconColor: const Color(0xFF10B981),
            child: Column(
              children: [
                _buildInfoRow(
                  lang == AppLanguage.my ? 'Backup အမျိုးအစား' : 'Backup Formats',
                  'Excel (CSV) & Full JSON',
                ),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(
                  lang == AppLanguage.my ? 'လုံခြုံရေး အဆင့်' : 'Security & Storage',
                  'Local Offline Storage (UTF-8 BOM)',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_for_offline, size: 16),
                  label: Text(
                    lang == AppLanguage.my ? 'Excel / JSON Backup ထုတ်ယူ & ပြန်သွင်းမည်' : 'Manage Excel & JSON Backups',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => BackupRestoreDialog.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 10. Telegram Support & Community Card
          _buildCard(
            title: lang == AppLanguage.my ? 'Telegram နည်းပညာ အကူအညီနှင့် ဝန်ဆောင်မှု' : 'Telegram Support & Upgrades',
            icon: Icons.support_agent,
            iconColor: const Color(0xFF38BDF8),
            child: Column(
              children: [
                _buildInfoRow(
                  lang == AppLanguage.my ? 'တရားဝင် ချန်နယ်' : 'Official Channel',
                  't.me/dotsoftwareservice',
                ),
                const Divider(color: Color(0xFF334155), height: 16),
                _buildInfoRow(
                  lang == AppLanguage.my ? 'တိုက်ရိုက် ဆက်သွယ်ရန်' : 'Direct Support',
                  '@khantlin0000',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.campaign, size: 16),
                        label: const Text('Channel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final uri = Uri.parse('https://t.me/dotsoftwareservice');
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            await launchUrl(uri, mode: LaunchMode.platformDefault);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Direct Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final uri = Uri.parse('https://t.me/khantlin0000');
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            await launchUrl(uri, mode: LaunchMode.platformDefault);
                          }
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

  Future<void> _handleEditAdmin(BuildContext context, WidgetRef ref, AppLanguage lang) async {
    final activeUser = ref.read(currentUserProvider);
    if (activeUser?.role == 'cashier') {
      final approved = await AdminOverrideDialog.requestApproval(
        context,
        actionTitle: 'Edit Admin Security PIN',
      );
      if (!approved) return;
    }

    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return;

    final userDao = ref.read(userDaoProvider);
    final users = await (userDao.select(userDao.users)
          ..where((t) => t.shopId.equals(shop.id) & t.role.equals('owner') & t.deletedAt.isNull()))
        .get();
    final ownerUser = users.isNotEmpty ? users.first : activeUser;

    if (!context.mounted) return;

    final nameController = TextEditingController(text: ownerUser?.name ?? 'Admin (Owner)');
    final pinController = TextEditingController(text: ownerUser?.pinCode ?? '1234');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang == AppLanguage.my ? 'အက်ဒမင် PIN ပြင်ဆင်ခြင်း' : 'Edit Admin PIN & Credentials',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.my ? 'အက်ဒမင် အမည် *' : 'Admin Name *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Admin name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.my ? 'လုံခြုံရေး PIN (၄ မှ ၆ လုံး) *' : 'Security PIN (4-6 digits) *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 4) {
                      return 'PIN must be at least 4 digits';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang == AppLanguage.my ? 'မလုပ်တော့ပါ' : 'Cancel', style: const TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final now = DateTime.now().toUtc();
                  if (ownerUser != null) {
                    await userDao.updateUser(
                      UsersCompanion(
                        id: drift.Value(ownerUser.id),
                        shopId: drift.Value(shop.id),
                        name: drift.Value(nameController.text.trim()),
                        pinCode: drift.Value(pinController.text.trim()),
                        role: const drift.Value('owner'),
                        updatedAt: drift.Value(now),
                        syncStatus: const drift.Value('pending'),
                      ),
                    );
                    final updated = await userDao.getUserById(ownerUser.id);
                    if (updated != null && ref.read(currentUserProvider)?.id == ownerUser.id) {
                      ref.read(currentUserProvider.notifier).setUser(updated);
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Text(
                          lang == AppLanguage.my
                              ? 'အက်ဒမင် PIN နှင့် အချက်အလက် အောင်မြင်စွာ ပြင်ဆင်ပြီးပါပြီ'
                              : 'Admin PIN and credentials updated successfully!',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                lang == AppLanguage.my ? 'သိမ်းမည်' : 'Save Changes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
