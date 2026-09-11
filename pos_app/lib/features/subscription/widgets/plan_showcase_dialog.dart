import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/localization/app_locale.dart';
import 'activation_dialog.dart';

class PlanShowcaseDialog extends ConsumerStatefulWidget {
  const PlanShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PlanShowcaseDialog(),
    );
  }

  @override
  ConsumerState<PlanShowcaseDialog> createState() => _PlanShowcaseDialogState();
}

class _PlanShowcaseDialogState extends ConsumerState<PlanShowcaseDialog> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(currentShopProvider);
    final lang = ref.watch(appLanguageProvider);
    final shop = shopAsync.value;
    final currentTier = shop?.planTier ?? 'free';
    final isPro = currentTier == 'pro';
    final isCustom = currentTier == 'custom';

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 1000, maxHeight: screenHeight * 0.90),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stars, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == AppLanguage.my ? 'DOT POS အစီအစဉ်များနှင့် ဈေးနှုန်းများ' : 'DOT POS Subscription Plans',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang == AppLanguage.my
                            ? 'သင့်လုပ်ငန်းအရွယ်အစားနှင့် ကိုက်ညီသော စနစ်ကို ရွေးချယ်ပါ'
                            : 'Choose the best plan tailored for your store operations',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3-Tier Comparison Cards with Responsive Scrolling
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 740;

                    if (isSmall) {
                      // Mobile View (Stacked Cards)
                      return SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(right: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFreeCard(context, ref, lang, isCurrent: !isPro && !isCustom),
                            const SizedBox(height: 14),
                            _buildProCard(context, ref, lang, isCurrent: isPro, shopId: shop?.id ?? ''),
                            const SizedBox(height: 14),
                            _buildCustomCard(context, ref, lang, isCurrent: isCustom, shopId: shop?.id ?? ''),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    }

                    // Tablet & Desktop View (Horizontal Row of 3 Columns with Vertical Scroll Support)
                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildFreeCard(context, ref, lang, isCurrent: !isPro && !isCustom)),
                          const SizedBox(width: 14),
                          Expanded(child: _buildProCard(context, ref, lang, isCurrent: isPro, shopId: shop?.id ?? '')),
                          const SizedBox(width: 14),
                          Expanded(child: _buildCustomCard(context, ref, lang, isCurrent: isCustom, shopId: shop?.id ?? '')),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildContactFooter(context, lang, shop?.id ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildContactFooter(BuildContext context, AppLanguage lang, String shopId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 6),
              Text(
                lang == AppLanguage.my ? 'အကူအညီနှင့် ဝယ်ယူရန် Telegram:' : 'Telegram Support & Sales:',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              InkWell(
                onTap: () => launchTelegramUrl('https://t.me/dotsoftwareservice'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign, color: Color(0xFF38BDF8), size: 14),
                      SizedBox(width: 4),
                      Text(
                        't.me/dotsoftwareservice',
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => launchTelegramUrl('https://t.me/khantlin0000'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2563EB)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, color: Color(0xFF60A5FA), size: 14),
                      SizedBox(width: 4),
                      Text(
                        '@khantlin0000',
                        style: TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> launchTelegramUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  void _showContactOptions(BuildContext context, String shopId, AppLanguage lang) {
    if (shopId.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: shopId));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == AppLanguage.my ? 'Telegram မှ ဆက်သွယ်ဝယ်ယူရန်' : 'Contact via Telegram',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (shopId.isNotEmpty)
                            Text(
                              lang == AppLanguage.my ? 'Shop ID ($shopId) ကို Copy ယူပြီးပါပြီ' : 'Shop ID ($shopId) copied to clipboard',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Button 1: Telegram Channel
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.campaign, size: 20),
                  label: const Text('Telegram Channel: t.me/dotsoftwareservice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    launchTelegramUrl('https://t.me/dotsoftwareservice');
                  },
                ),
                const SizedBox(height: 10),
                // Button 2: Direct Chat
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat, size: 20),
                  label: const Text('Direct Chat: @khantlin0000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    launchTelegramUrl('https://t.me/khantlin0000');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyShopIdAndContact(BuildContext context, String shopId, AppLanguage lang) {
    _showContactOptions(context, shopId, lang);
  }

  Widget _buildFreeCard(BuildContext context, WidgetRef ref, AppLanguage lang, {required bool isCurrent}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF334155),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FREE PLAN',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Text(
                    lang == AppLanguage.my ? 'လက်ရှိအသုံးပြုဆဲ' : 'Active Plan',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.tr('plan_free_price', lang),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            lang == AppLanguage.my
                ? 'ဆိုင်တစ်ဆိုင်တည်း အင်တာနက်မလိုဘဲ အော့ဖ်လိုင်းသုံးရန် အထူးသင့်လျော်ပါသည်'
                : '100% offline standalone POS for single shop',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          _buildFeatureItem(lang == AppLanguage.my ? '100% Offline SQLite ACID အော့ဖ်လိုင်း စနစ်' : '100% Offline SQLite ACID Database'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Language (မြန်မာစာ 🇲🇲 / English 🇬🇧 ဘာသာစကား)' : 'Bilingual Support (Myanmar & English)'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Barcode Scan Gun (ကင်မရာ & USB/BT စကန်ဖတ်စက်)' : 'Barcode Scanner (Camera & Scan Gun HID)'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Category (ကုန်ပစ္စည်း အမျိုးအစား & အရောင်ခွဲစနစ်)' : 'Product Categories with Color Codes'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Shop Profile (ဆိုင်အချက်အလက် & ငွေကြေးသတ်မှတ်မှု)' : 'Shop Profile & Currency Setup (MMK/USD/THB)'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Cashier PIN (ဝန်ထမ်း PIN & Lock Screen စနစ်)' : 'Cashier PIN Security & Lock Screen'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Excel & JSON Data Backup (ဒေတာ သိမ်းဆည်းမှု)' : 'Excel (CSV) & JSON Local Data Backup'),
          _buildFeatureItem(lang == AppLanguage.my ? 'အရောင်းနှင့် ဘောက်ချာ အကန့်အသတ်မရှိ ထုတ်ယူနိုင်ခြင်း' : 'Unlimited Orders & Thermal Invoices'),
          _buildFeatureItem(lang == AppLanguage.my ? 'စတော့စာရင်း၊ အဝင်/အထွက် & ပျက်စီးဆုံးရှုံးမှု' : 'Inventory Tracking, Stock In/Out & Wastage'),
          _buildFeatureItem(lang == AppLanguage.my ? 'ဖောက်သည် စာရင်းနှင့် အကြွေး/ကြွေးဆပ် မှတ်တမ်း' : 'Customer CRM & Debt Repayment Ledger'),
          _buildFeatureItem(lang == AppLanguage.my ? '58mm / 80mm Thermal Receipt ပရင်တာ ချိတ်ဆက်မှု' : '58mm / 80mm ESC/POS Thermal Printers'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Sale Invoice (အရောင်းဘောက်ချာ မှတ်တမ်း & ပြေစာထုတ်)' : 'Sale Invoice History & Thermal Re-print'),
          _buildFeatureItem(lang == AppLanguage.my ? 'အဆိုင်းဖွင့်/ပိတ်၊ Pay In/Out & ငွေစာရင်းစစ်ဆေးမှု' : 'Shift Management, Pay In/Out & Audit'),
          _buildFeatureItem(lang == AppLanguage.my ? 'နေ့စဉ် Z-Report စာရင်းချုပ် & စာရင်းစစ် ပြေစာ' : 'Daily Z-Report & Audit Summary Slips'),
        ],
      ),
    );
  }

  Widget _buildProCard(BuildContext context, WidgetRef ref, AppLanguage lang, {required bool isCurrent, required String shopId}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRO PLAN',
                style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Text(
                  isCurrent
                      ? (lang == AppLanguage.my ? 'လက်ရှိအသုံးပြုဆဲ' : 'Active Plan')
                      : (lang == AppLanguage.my ? 'လူကြိုက်အများဆုံး' : 'Most Popular'),
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.tr('plan_pro_price', lang),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            lang == AppLanguage.my
                ? 'UOM, Promotion, Purchase, Warehouse နှင့် Offline Sync ပါဝင်သော အဆင့်မြင့်စနစ်'
                : 'Complete retail & wholesale suite with offline sync',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          _buildFeatureItem(lang == AppLanguage.my ? 'FREE စနစ်ပါ အင်္ဂါရပ်အားလုံး အပြည့်အစုံ' : 'Everything in FREE plan, plus:'),
          _buildFeatureItem(lang == AppLanguage.my ? 'UOM (ယူနစ် အတိုင်းအတာ စီမံခန့်ခွဲမှု)' : 'UOM (Unit of Measure)'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Promotion (ပရိုမိုးရှင်း အစီအစဉ်များ)' : 'Promotion Management'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Purchase (အဝယ်စာရင်း & ပေးသွင်းသူများ)' : 'Purchase & Supplier Tracking'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Warehouse (ဂိုဒေါင် & စတော့ ထိန်းချုပ်မှု)' : 'Warehouse Stock Management'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Return (ကုန်ပစ္စည်း အဝင်/အထွက် ပြန်သွင်း)' : 'Sales & Purchase Returns'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Discount (ရာခိုင်နှုန်း & ငွေပမာဏ လျှော့စျေး)' : 'Discounts (% & Fixed)'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Loyalty (ဖောက်သည် Point & Loyalty စနစ်)' : 'Customer Loyalty & Rewards'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Price List (စျေးနှုန်းစာရင်း အဆင့်ဆင့်)' : 'Custom Price Lists'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Repost (စာရင်းပြန်ထုတ် & အဆင့်မြင့် အစီရင်ခံစာ)' : 'Repost & Advanced Reports'),
          _buildFeatureItem(lang == AppLanguage.my ? 'PDF Invoice (ဒစ်ဂျစ်တယ် ဘောက်ချာ & ရှယ်ယာပြုလုပ်ခြင်း)' : 'PDF Digital Invoice Export & Share'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Offline Sync (100% အော့ဖ်လိုင်း & Multi-Device Sync)' : 'Offline Sync & Multi-Device Sync'),
          _buildFeatureItem(lang == AppLanguage.my ? 'ဖုန်းနှင့် Tablet စက်များစွာ ချိတ်ဆက်ရောင်းနိုင်ခြင်း' : 'Multi-device Concurrent POS Terminals'),
          _buildFeatureItem(lang == AppLanguage.my ? 'နေ့စဉ် အလိုအလျောက် Cloud Backup' : 'Daily Automated Cloud Backup'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Telegram Priority နည်းပညာ အကူအညီ' : 'Priority Support via Telegram'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send, size: 16),
            label: Text(
              lang == AppLanguage.my ? 'Telegram မှ ဝယ်ယူမည်' : 'Upgrade via Telegram',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () => _copyShopIdAndContact(context, shopId, lang),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF60A5FA),
              side: const BorderSide(color: Color(0xFF3B82F6)),
              minimumSize: const Size(double.infinity, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ActivationDialog.show(context);
            },
            child: Text(
              lang == AppLanguage.my ? 'လိုင်စင်ကုတ် ရိုက်ထည့်မည်' : 'Enter License Key',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCard(BuildContext context, WidgetRef ref, AppLanguage lang, {required bool isCurrent, required String shopId}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFFA855F7) : const Color(0xFF334155),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CUSTOM PLAN',
                style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA855F7)),
                ),
                child: Text(
                  lang == AppLanguage.my ? 'ဆိုင်ခွဲကြီးများအတွက်' : 'For Chain Stores',
                  style: const TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.tr('plan_custom_price', lang),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            lang == AppLanguage.my
                ? 'HR, CRM, Branch, AI Chat, Accounting နှင့် စိတ်ကြိုက် Enterprise စနစ်ကြီးများအတွက်'
                : 'HR, CRM, Branches, AI Assistant, Accounting & Enterprise solutions',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          _buildFeatureItem(lang == AppLanguage.my ? 'PRO စနစ်ပါ အင်္ဂါရပ်အားလုံး အပြည့်အစုံ' : 'Everything in PRO plan, plus:'),
          _buildFeatureItem(lang == AppLanguage.my ? 'HR Management (ဝန်ထမ်းရေးရာ စီမံခန့်ခွဲမှု)' : 'HR Management'),
          _buildFeatureItem(lang == AppLanguage.my ? 'CRM Management (ဖောက်သည် ဆက်ဆံရေး စီမံခန့်ခွဲမှု)' : 'CRM Management'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Branch Management (ဆိုင်ခွဲများ ကွင်းဆက် စီမံမှု)' : 'Branch Management'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Administration (အဆင့်မြင့် စီမံခန့်ခွဲမှု & Permissions)' : 'Central Administration'),
          _buildFeatureItem(lang == AppLanguage.my ? 'AI Assistant Chat (အရောင်း & စတော့ AI အထောက်အကူ)' : 'AI Assistant Chat'),
          _buildFeatureItem(lang == AppLanguage.my ? '24/7 Customer Service Bot (၂၄ နာရီ ဝန်ဆောင်မှု Bot)' : '24/7 Customer Service Bot'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Accounting / Finance (ဘဏ္ဍာရေး & စာရင်းကိုင်စနစ်)' : 'Accounting / Finance'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Custom ERP / API Integration (စိတ်ကြိုက် စနစ်များ)' : 'Custom ERP & API Integrations'),
          _buildFeatureItem(lang == AppLanguage.my ? 'သီးသန့် Database & Cloud Server Hosting' : 'Dedicated Database & Cloud Server'),
          _buildFeatureItem(lang == AppLanguage.my ? 'စိတ်ကြိုက် Enterprise စနစ်များ (etc)' : 'Custom Enterprise Integrations & etc'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.business, size: 16),
            label: Text(
              lang == AppLanguage.my ? 'Enterprise ဆက်သွယ်ရန်' : 'Contact Sales',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () => _copyShopIdAndContact(context, shopId, lang),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
