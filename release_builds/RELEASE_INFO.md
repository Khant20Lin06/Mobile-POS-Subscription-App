# DOT POS - Multi-Platform Release Documentation (v1.0.0)

ဤ Folder ထဲတွင် Google Play Store တင်ရန် **Android App Bundle (AAB)**၊ Android ဖုန်းများနှင့် Sunmi/iMin POS စက်များတွင် တိုက်ရိုက် သွင်းယူအသုံးပြုနိုင်သည့် **Signed APK**၊ Windows Desktop အတွက် **Portable x64 Package** နှင့် Apple iOS / macOS အတွက် **Full Source Archive** တို့ကို အဆင့်သင့် ထုတ်ယူသိမ်းဆည်းပေးထားပါသည်။

---

## 📁 Release Artifacts

| File Name | Platform / Type | File Size | Description & Usage |
| :--- | :--- | :--- | :--- |
| **`DOT-POS-v1.0.0.apk`** | Android Direct Install | **~85 MB** | Android Phones, Tablets, Sunmi V2/D2, iMin စက်များတွင် တိုက်ရိုက် Install ပြုလုပ်ရန် Signed Release APK |
| **`DOT-POS-v1.0.0.aab`** | Android Play Console | **~63 MB** | Google Play Store Console > Production/Internal Testing သို့ တင်ရန် သီးသန့်ထုတ်ထားသော App Bundle |
| **`DOT-POS-Windows-x64-v1.0.0.zip`** | Windows x64 Portable | **~20 MB** | Windows 10/11 PC/Laptop/POS များတွင် Install လုပ်စရာမလိုဘဲ တိုက်ရိုက် ဖြည်ပြီး အသုံးပြုနိုင်သော Standalone Package |
| **`DOT-POS-Apple-iOS-macOS-Sources.zip`** | Apple iOS & macOS | **~1 MB** | macOS / Xcode တွင် တိုက်ရိုက် `flutter build ipa` သို့မဟုတ် `flutter build macos` ထုတ်ယူရန် Ready-to-compile Bundle |
| **`playstore-512x512.png`** | High-Res Official Icon | **118 KB** | Google Play Console Store Listing အတွက် 512x512 App Icon |

---

## ⚡ Core Hardware & Enterprise Features (v1.0.0)

### 1. Thermal Receipt Printing (ESC/POS & Native Bluetooth)
- **Supported Connection Types**:
  - **Native Bluetooth Thermal (SPP / RFCOMM)**: Android စနစ်၏ paired Bluetooth device များကို auto scan ရှာဖွေပေးခြင်း၊ Standard Serial Port Profile (UUID `00001101-0000-1000-8000-00805F9B34FB`) ဖြင့် တိုက်ရိုက် binary ESC/POS data ပို့ဆောင်ပေးခြင်း။ ချိတ်ဆက်မှုမရှိပါက Disconnected အမှန်အတိုင်း ပြသပေးပြီး Test Connection စစ်ဆေးနိုင်ခြင်း။
  - **Network / LAN / Wi-Fi**: Raw TCP Socket (Port 9100) — တိုက်ရိုက် IP လိပ်စာဖြင့် မြန်ဆန်စွာ slip ထုတ်ပေးခြင်း
  - **Sunmi / iMin Built-in Spooler**: Built-in thermal printer ပါရှိသော Android POS terminal များအတွက် auto spooling
  - **USB & OS System Print**: Android / Windows default print dialog သို့ forwarding
- **Paper Formats**: 58mm (Receipt standard) နှင့် 80mm (Wide receipt standard)
- **Features**: Shop Header Logo, Center-aligned Shop Details, Myanmar Zawgyi/Unicode font formatting, Cash Drawer Kick-out command (`ESC p`), Paper Auto-cut command (`GS V 66 0`)။ PDF slip များကိုလည်း A4/Letter စာရွက်များတွင် Center တည့်တည့်တွင်သာ alignment ထားရှိပေးထားပါသည်။

### 2. Barcode Scanning & Scan Gun Integration
- **Interactive Camera Barcode Scanner**:
  - POS Search Bar ရှိ Scan Icon ကို နှိပ်လိုက်သည်နှင့် Fullscreen Camera Scanner ပွင့်လာမည်ဖြစ်ပြီး Flashlight (Torch) ဖွင့်/ပိတ်ခြင်း၊ Camera ရှေ့/နောက် ပြောင်းလဲခြင်းများ ပြုလုပ်နိုင်ပါသည်။
  - Scan ဖတ်မိသည်နှင့် Beep အသံမြည်ကာ Cart ထဲသို့ Product ကို auto ထည့်သွင်းပေးပါသည်။
- **Hardware Barcode Scan Guns (USB & Bluetooth)**:
  - **USB Barcode Scanners**: Plug & Play USB HID keyboard wedge mode
  - **Bluetooth Barcode Scanners**: Wireless Bluetooth HID mode
  - **Truth-in-Status Reporting**: Scan gun settings တွင် ချိတ်ဆက်မှုအချက်ပြ signal မရသေးဘဲ "Connected" လို့ မပြဘဲ "Waiting for Scan Signal" ဖြင့်သာ စောင့်ဆိုင်းပြီး အမှန်တကယ် signal ရမှသာ "Connected & Verified" သို့ ပြောင်းလဲပေးပါသည်။
- **Integration Points**:
  - **POS Sales Screen**: Barcode ပစ်လိုက်သည်နှင့် Cart ထဲသို့ တိုက်ရိုက် Product ထည့်သွင်းပေးခြင်း
  - **Inventory Screen**: Barcode Scan ဖတ်၍ ပစ္စည်းရှာဖွေခြင်း၊ Stock In / Out အမြန်ပြုလုပ်ခြင်း

### 3. Permissions & Platform Compatibility
- **Android**:
  - `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, `ACCESS_FINE_LOCATION` (Android 12+ နှင့် Android 6-11 အားလုံးအတွက် Runtime Permission Request dialog များ တိုက်ရိုက် native OS level တွင် တောင်းဆိုပေးခြင်း)
  - `CAMERA` (ဖုန်း camera ဖြင့် barcode ဖတ်ရန် runtime permission auto request)
  - `INTERNET`, `ACCESS_NETWORK_STATE`
- **iOS / macOS**:
  - `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`, `NSCameraUsageDescription` pre-configured in `Info.plist`.

---

## ⚙️ Android Keystore Information

- **Package Name / App ID**: `com.khantlin.mobile_pos`
- **Version Name**: `1.0.0`
- **Version Code**: `1`
- **Target SDK**: Android 34 / 36 (Google Play Store Compliant)
- **Min SDK**: Android 21 (Android 5.0 Lollipop နှင့် အထက် အားလုံး support)
- **Keystore**: `pos_app/android/app/upload-keystore.jks`
- **Key Alias**: `upload`
- **Password**: `posapp2026`

---

## 🚀 How to Run & Deploy

### A. Android Installation
- ဖုန်း သို့မဟုတ် Sunmi/iMin POS စက်သို့ `DOT-POS-v1.0.0.apk` ကို ကူးယူပြီး Open / Install နှိပ်၍ အသုံးပြုနိုင်ပါသည်။

### B. Google Play Store Console Upload
1. [Google Play Console](https://play.google.com/console) သို့ ဝင်ရောက်ပါ။
2. **Create App** > App Name: `DOT POS` > Free App အဖြစ် သတ်မှတ်ပါ။
3. Store Presence > Main Store Listing တွင် `playstore-512x512.png` ကို Upload တင်ပါ။
4. Production > Create new release တွင် `DOT-POS-v1.0.0.aab` ကို Upload တင်ပြီး Release ပြုလုပ်ပါ။

### C. Windows Desktop
1. `DOT-POS-Windows-x64-v1.0.0.zip` ကို Right Click နှိပ်ပြီး **Extract All** ပြုလုပ်ပါ။
2. ဖိုဒါထဲရှိ `pos_app.exe` ကို Double Click နှိပ်၍ ချက်ချင်း အသုံးပြုနိုင်ပါသည်။ (Desktop Shortcut ပြုလုပ်ထားနိုင်ပါသည်)
