# DOT POS - Google Play Store & Android Release Information

ဤ Folder ထဲတွင် Google Play Store ပေါ်သို့ တင်ရန် **AAB File**၊ Android ဖုန်းများ / Sunmi POS စက်များတွင် တိုက်ရိုက် သွင်းယူအသုံးပြုနိုင်သည့် **Signed APK File** နှင့် Play Console အတွက် **512x512 High-Res Icon** တို့ကို ထုတ်ယူသိမ်းဆည်းပေးထားပါသည်။

---

## 📁 Release Files Details

| File Name | File Type | File Size | Description |
| :--- | :--- | :--- | :--- |
| **`DOT-POS-v1.0.0.aab`** | Android App Bundle | **48.1 MB** | **Google Play Console (Play Store)** ပေါ်သို့ တင်ရန် သီးသန့်ထုတ်ထားသော Production Bundle |
| **`DOT-POS-v1.0.0.apk`** | Signed Release APK | **59.1 MB** | Android Phone, Tablet, Sunmi/iMin POS စက်များတွင် **Direct Install (Side-load)** လုပ်ရန် |
| **`playstore-512x512.png`** | 512x512 PNG Icon | **118 KB** | Google Play Console > Store Listing တွင် တင်ရန် **Official App Icon** |

---

## ⚙️ Application & Keystore Details

- **Application Name**: `DOT POS`
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
   - App Name: `DOT POS`
   - Default language: `English (United States)` သို့မဟုတ် `Burmese`
   - App or game: `App`
   - Free or paid: `Free`
3. **Store Presence** > **Main store listing** တွင်:
   - App Icon နေရာ၌ `release_builds/playstore-512x512.png` ကို Upload တင်ပါ။
4. **Release** > **Production** (သို့မဟုတ် **Internal testing**) သို့ သွားပါ။
5. **Create new release** ကို နှိပ်ပါ။
6. `release_builds/DOT-POS-v1.0.0.aab` ဖိုင်ကို **App bundles** နေရာတွင် Drag & Drop ဆွဲထည့်ပြီး Upload ပြုလုပ်ပါ။
7. Release Notes ရေးသားပြီး **Review & Save** ပြုလုပ်၍ Play Store သို့ Submit တင်နိုင်ပြီ ဖြစ်ပါသည်။
