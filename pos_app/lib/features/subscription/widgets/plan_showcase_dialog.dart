import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/localization/app_locale.dart';
import 'activation_dialog.dart';

class PlanShowcaseDialog extends ConsumerWidget {
  const PlanShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PlanShowcaseDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        width: 850,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
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

            // 3-Tier Comparison Cards
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 680;

                  if (isSmall) {
                    return SingleChildScrollView(
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

                  return SingleChildScrollView(
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
          ],
        ),
      ),
    );
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
          _buildFeatureItem(lang == AppLanguage.my ? '100% Offline SQLite ACID စနစ်' : '100% Offline SQLite ACID Ready'),
          _buildFeatureItem(lang == AppLanguage.my ? 'အရောင်းနှင့် ဘောက်ချာ အကန့်အသတ်မရှိ' : 'Unlimited Orders & Invoices'),
          _buildFeatureItem(lang == AppLanguage.my ? 'စတော့စာရင်းနှင့် အဝင်/အထွက်' : 'Product & Stock Management'),
          _buildFeatureItem(lang == AppLanguage.my ? 'ဖောက်သည် & အကြွေးစာရင်း' : 'Customer CRM & Debt Repayment'),
          _buildFeatureItem(lang == AppLanguage.my ? '58mm / 80mm Thermal Receipt Print' : '58mm/80mm Thermal Receipts'),
          _buildFeatureItem(lang == AppLanguage.my ? 'ကက်ရှာ PIN နှင့် အဆိုင်းစစ်ဆေးခြင်း' : 'Cashier PIN & Shift Drawers'),
          _buildFeatureItem(lang == AppLanguage.my ? 'နေ့စဉ် Z-Report စာရင်းချုပ်' : 'Daily Z-Report & Audit Slip'),
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
                ? 'ဖုန်းနှင့် Tablet စက်များစွာ ချိတ်ဆက်ပြီး Cloud Delta Sync သုံးလိုသူများအတွက်'
                : 'Real-time multi-device cloud delta sync & backup',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          _buildFeatureItem(lang == AppLanguage.my ? 'FREE စနစ်ပါ အင်္ဂါရပ်အားလုံး အပြည့်အစုံ' : 'Everything in FREE plan, plus:'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Real-time Cloud Delta Sync' : 'Real-time Cloud Delta Sync'),
          _buildFeatureItem(lang == AppLanguage.my ? 'ဖုန်း/Tablet စက်များစွာ ချိတ်ဆက်ရောင်းနိုင်ခြင်း' : 'Multi-device Live Syncing'),
          _buildFeatureItem(lang == AppLanguage.my ? 'နေ့စဉ် အလိုအလျောက် Cloud Backup' : 'Daily Automated Cloud Backup'),
          _buildFeatureItem(lang == AppLanguage.my ? 'အဝေးရောက် Web Dashboard ကြည့်ရှုခွင့်' : 'Remote Web Dashboard Access'),
          _buildFeatureItem(lang == AppLanguage.my ? 'Telegram Priority အကူအညီ' : 'Priority Support via Telegram'),
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
                ? 'ဆိုင်ခွဲများစွာ၊ ဗဟိုဂိုဒေါင်နှင့် စိတ်ကြိုက် ERP ချိတ်ဆက်လိုသော လုပ်ငန်းကြီးများအတွက်'
                : 'Multi-branch retail chains & custom ERP integrations',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          _buildFeatureItem(lang == AppLanguage.my ? 'PRO စနစ်ပါ အင်္ဂါရပ်အားလုံး အပြည့်အစုံ' : 'Everything in PRO plan, plus:'),
          _buildFeatureItem(lang == AppLanguage.my ? 'ဆိုင်ခွဲအကန့်အသတ်မရှိ ကွင်းဆက်စနစ်' : 'Unlimited Store Chains & Branches'),
          _buildFeatureItem(lang == AppLanguage.my ? 'ဗဟိုဂိုဒေါင် & ဆိုင်ခွဲများ အပြန်အလှန် လွှဲပြောင်း' : 'Central Warehouse Stock Transfer'),
          _buildFeatureItem(lang == AppLanguage.my ? 'စိတ်ကြိုက် ERP / Accounting API Integration' : 'Custom ERP / API Integration'),
          _buildFeatureItem(lang == AppLanguage.my ? 'စိတ်ကြိုက် ဘောက်ချာဒီဇိုင်း & Logo အမှတ်တံဆိပ်' : 'Custom Thermal Receipt Branding'),
          _buildFeatureItem(lang == AppLanguage.my ? 'သီးသန့် Database & Server Hosting' : 'Dedicated Database & Server'),
          _buildFeatureItem(lang == AppLanguage.my ? '၂၄/၇ ဖုန်း & On-site အထူးဝန်ဆောင်မှု' : '24/7 Dedicated Support Agent'),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
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

  void _copyShopIdAndContact(BuildContext context, String shopId, AppLanguage lang) {
    Clipboard.setData(ClipboardData(text: shopId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2563EB),
        content: Text(
          lang == AppLanguage.my
              ? 'Shop ID ($shopId) ကို Copy ယူပြီးပါပြီ။ Telegram: @khantlin0000 သို့ ဆက်သွယ်ပေးပါ။'
              : 'Shop ID copied! Please contact Telegram: @khantlin0000',
        ),
      ),
    );
  }
}
