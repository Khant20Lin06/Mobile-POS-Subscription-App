import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported Languages
enum AppLanguage {
  en('en', 'English (EN)', '🇬🇧'),
  my('my', 'မြန်မာစာ (MM)', '🇲🇲');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);
}

/// Active App Language StateNotifier
class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.my); // Default to Myanmar for local store operators

  void setLanguage(AppLanguage lang) {
    state = lang;
  }

  void toggleLanguage() {
    state = state == AppLanguage.en ? AppLanguage.my : AppLanguage.en;
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier();
});

/// Central Dictionary of Translations
class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    // Navigation
    'nav_register': {'en': 'Register', 'my': 'အရောင်း'},
    'nav_inventory': {'en': 'Inventory', 'my': 'စတော့'},
    'nav_customers': {'en': 'Customers', 'my': 'ဖောက်သည်'},
    'nav_zreport': {'en': 'Z-Report', 'my': 'ဇက်-အစီရင်ခံစာ'},
    'nav_settings': {'en': 'Settings', 'my': 'ဆက်တင်များ'},
    'nav_dbsync': {'en': 'DB & Sync', 'my': 'ဒေတာ & ဆင့်ခ်'},

    // Common & POS
    'pos_search_hint': {'en': 'Search or Scan Barcode...', 'my': 'ပစ္စည်းရှာဖွေရန် / ဘားကုဒ်စကန်ဖတ်ရန်...'},
    'pos_all_items': {'en': 'All Items', 'my': 'ပစ္စည်းအားလုံး'},
    'pos_open_shift': {'en': 'Open Shift', 'my': 'အဆိုင်းဖွင့်'},
    'pos_shift': {'en': 'Shift', 'my': 'အဆိုင်း'},
    'pos_cashier': {'en': 'Cashier', 'my': 'ကက်ရှာ'},
    'pos_cart': {'en': 'Cart', 'my': 'စျေးခြင်း'},
    'pos_empty_cart': {'en': 'Cart is empty', 'my': 'ခြင်းတောင်းထဲတွင် ပစ္စည်းမရှိသေးပါ'},
    'pos_charge': {'en': 'Charge', 'my': 'ငွေရှင်းမည်'},
    'pos_out_of_stock': {'en': 'Out', 'my': 'ကုန်ပြီ'},
    'pos_sync_cloud': {'en': 'Sync to Cloud', 'my': 'Cloud သို့ သိမ်းမည်'},

    // Inventory & Categories
    'inv_products': {'en': 'Products', 'my': 'ကုန်ပစ္စည်းများ'},
    'inv_add_product': {'en': 'Add Product', 'my': 'ပစ္စည်းအသစ်ထည့်'},
    'inv_edit_product': {'en': 'Edit Product', 'my': 'ပစ္စည်းပြင်ဆင်ရန်'},
    'inv_delete_product': {'en': 'Delete Product', 'my': 'ပစ္စည်းဖျက်ရန်'},
    'inv_total_items': {'en': 'Total Items', 'my': 'စုစုပေါင်းပစ္စည်း'},
    'inv_total_units': {'en': 'Total Units', 'my': 'စုစုပေါင်းအရေအတွက်'},
    'inv_low_stock': {'en': 'Low Stock', 'my': 'လက်ကျန်နည်း'},
    'inv_stock_value': {'en': 'Stock Valuation', 'my': 'စတော့တန်ဖိုး'},
    'inv_manage_categories': {'en': 'Manage Categories', 'my': 'အမျိုးအစားများ စီမံရန်'},
    'inv_categories': {'en': 'Categories', 'my': 'အမျိုးအစားများ'},
    'inv_add_category': {'en': 'Add Category', 'my': 'အမျိုးအစားအသစ်'},
    'inv_edit_category': {'en': 'Edit Category', 'my': 'အမျိုးအစားပြင်ဆင်ရန်'},
    'inv_delete_category': {'en': 'Delete Category', 'my': 'အမျိုးအစားဖျက်ရန်'},
    'inv_category_name': {'en': 'Category Name', 'my': 'အမျိုးအစားအမည်'},
    'inv_choose_color': {'en': 'Select Color', 'my': 'အရောင်ရွေးချယ်ပါ'},
    'inv_stock_movement': {'en': 'Stock In / Out', 'my': 'စတော့ အဝင်/အထွက်'},

    // Customer & Debt
    'cust_title': {'en': 'Customers & Debt', 'my': 'ဖောက်သည် & အကြွေး'},
    'cust_add': {'en': 'Add Customer', 'my': 'ဖောက်သည်အသစ်'},
    'cust_total': {'en': 'Total Customers', 'my': 'ဖောက်သည်ဦးရေ'},
    'cust_total_debt': {'en': 'Market Debt', 'my': 'စုစုပေါင်းအကြွေးကျန်'},
    'cust_repay': {'en': 'Repay Debt', 'my': 'အကြွေးဆပ်မည်'},

    // Plans & Subscription
    'plan_free': {'en': 'FREE (Offline Ready)', 'my': 'FREE (အော့ဖ်လိုင်းအသုံးပြုခွင့်)'},
    'plan_pro': {'en': 'PRO (Cloud Active)', 'my': 'PRO (ကလောက်ချိတ်ဆက်စနစ်)'},
    'plan_custom': {'en': 'CUSTOM (Enterprise)', 'my': 'CUSTOM (ဆိုင်ခွဲကွင်းဆက်စနစ်)'},
    'plan_view_all': {'en': 'View All Plans', 'my': 'အစီအစဉ်များအားလုံး ကြည့်ရန်'},
    'plan_activate': {'en': 'Activate License', 'my': 'လိုင်စင်ရိုက်ထည့်မည်'},
    'plan_free_price': {'en': '0 MMK / Forever Free', 'my': 'အခမဲ့ / တစ်သက်တာ'},
    'plan_pro_price': {'en': '15,000 MMK / Month', 'my': '၁၅,၀၀၀ ကျပ် / တစ်လ'},
    'plan_custom_price': {'en': 'Custom Quote', 'my': 'စိတ်ကြိုက်ညှိနှိုင်း'},

    // Settings
    'set_title': {'en': 'Settings & Preferences', 'my': 'ဆက်တင်များနှင့် စီမံခန့်ခွဲမှု'},
    'set_language': {'en': 'Language (ဘာသာစကား)', 'my': 'Language (ဘာသာစကား)'},
    'set_shop_profile': {'en': 'Shop Profile', 'my': 'ဆိုင်အချက်အလက်'},
    'set_printer': {'en': 'Thermal Printer', 'my': 'ဘောက်ချာ ပရင်တာ'},
    'set_receipt_note': {'en': 'Receipt Footer Note', 'my': 'ဘောက်ချာအောက်ခြေစာသား'},
    'set_security': {'en': 'Cashier PIN & Security', 'my': 'ကက်ရှာ PIN & လုံခြုံရေး'},
    'set_data_cloud': {'en': 'Data & Cloud Sync', 'my': 'ဒေတာ & Cloud ချိတ်ဆက်မှု'},

    // Common Actions
    'btn_save': {'en': 'Save Changes', 'my': 'သိမ်းဆည်းမည်'},
    'btn_cancel': {'en': 'Cancel', 'my': 'မလုပ်တော့ပါ'},
    'btn_delete': {'en': 'Delete', 'my': 'ဖျက်မည်'},
    'btn_edit': {'en': 'Edit', 'my': 'ပြင်ဆင်မည်'},
    'btn_close': {'en': 'Close', 'my': 'ပိတ်မည်'},
    'btn_confirm': {'en': 'Confirm', 'my': 'အတည်ပြုသည်'},
    'btn_upgrade': {'en': 'Upgrade via Telegram', 'my': 'Telegram မှတစ်ဆင့် ဝယ်ယူမည်'},
  };

  static String tr(String key, AppLanguage lang) {
    final entry = _localizedValues[key];
    if (entry == null) return key;
    return entry[lang.code] ?? entry['en'] ?? key;
  }
}

/// Easy BuildContext extension for translations
extension TranslationExtension on BuildContext {
  String tr(String key, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return AppTranslations.tr(key, lang);
  }
}
