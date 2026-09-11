# Mobile POS - Google Play Store & Android Release Information

ဤ Folder ထဲတွင် Google Play Store ပေါ်သို့ တင်ရန် **AAB File** နှင့် Android ဖုန်းများ / Sunmi POS စက်များတွင် တိုက်ရိုက် သွင်းယူအသုံးပြုနိုင်သည့် **APK File** နှစ်ခုလုံးကို ထုတ်ယူသိမ်းဆည်းပေးထားပါသည်။

---

## 📁 Release Files Details

| File Name | File Type | File Size | Description |
| :--- | :--- | :--- | :--- |
| **`Mobile-POS-v1.0.0.aab`** | Android App Bundle | ~47.4 MB | **Google Play Console (Play Store)** ပေါ်သို့ တင်ရန် သီးသန့်ထုတ်ထားသော Format |
| **`Mobile-POS-v1.0.0.apk`** | Signed Release APK | ~57.3 MB | Android Phone, Tablet, Sunmi/iMin POS စက်များတွင် **Direct Install (Side-load)** လုပ်ရန် |

---

## ⚙️ Application & Keystore Details

- **Application Name**: Mobile POS
- **Package Name / Application ID**: `com.khantlin.mobile_pos`
- **Version Name**: `1.0.0`
- **Version Code**: `1`
- **Target SDK**: Android 34 / 36 (Latest Google Play Requirement)
- **Min SDK**: Android 21 (Android 5.0 Lollipop နှင့် အထက် စက်အားလုံး အသုံးပြုနိုင်ပါသည်)
- **Keystore Path**: `pos_app/android/app/upload-keystore.jks`
- **Key Alias**: `upload`
- **Store Password**: `posapp2026`
- **Key Password**: `posapp2026`

---

## 🛡️ Configured Permissions

- `android.permission.INTERNET` (Cloud Delta Sync & License Validation အတွက်)
- `android.permission.ACCESS_NETWORK_STATE` (အင်တာနက် ချိတ်ဆက်မှု အခြေအနေ စစ်ဆေးရန်)
- `android.permission.BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` (ESC/POS Thermal Receipt Printer များ ချိတ်ဆက်ရန်)

---

## 🚀 Play Store Console ပေါ်သို့ တင်နည်း အဆင့်ဆင့် (How to upload to Play Store)

1. **Google Play Console** (`https://play.google.com/console`) သို့ သွားရောက်ပါ။
2. **Create App** ကို နှိပ်ပြီး:
   - App Name: `Mobile POS` (သို့မဟုတ် မိမိပေးလိုသော အမည်)
   - Default language: `English (United States)` သို့မဟုတ် `Burmese`
   - App or game: `App`
   - Free or paid: `Free` (App အတွင်းတွင်မှ Subscription စနစ်ဖြင့် သွားမည်ဖြစ်သောကြောင့်)
3. **Production** သို့မဟုတ် **Internal Testing** Tab သို့ သွားပါ။
4. **Create new release** ကို နှိပ်ပါ။
5. `release_builds/Mobile-POS-v1.0.0.aab` ဖိုင်ကို **App bundles** နေရာတွင် Drag & Drop ဆွဲထည့်ပြီး Upload ပြုလုပ်ပါ။
6. Release Notes ရေးသားပြီး **Review & Save** ပြုလုပ်၍ Play Store သို့ Submit တင်နိုင်ပြီ ဖြစ်ပါသည်။
