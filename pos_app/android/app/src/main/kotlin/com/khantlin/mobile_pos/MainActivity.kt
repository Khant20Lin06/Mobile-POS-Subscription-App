package com.khantlin.mobile_pos

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.UUID
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.khantlin.mobile_pos/hardware"
    private val PERMISSION_REQUEST_CODE = 1001
    private var pendingPermissionResult: MethodChannel.Result? = null

    // Standard SPP UUID for ESC/POS Bluetooth Thermal Printers
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkBluetoothPermissions" -> {
                    result.success(hasBluetoothPermissions())
                }
                "requestBluetoothPermissions" -> {
                    if (hasBluetoothPermissions()) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        val permissions = getRequiredBluetoothPermissions()
                        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
                    }
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.localizedMessage, null)
                    }
                }
                "getBluetoothPrinters" -> {
                    if (!hasBluetoothPermissions()) {
                        result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
                        return@setMethodCallHandler
                    }
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter == null) {
                        result.error("BLUETOOTH_UNAVAILABLE", "Device does not support Bluetooth", null)
                        return@setMethodCallHandler
                    }
                    if (!adapter.isEnabled) {
                        result.error("BLUETOOTH_DISABLED", "Bluetooth is turned off on device", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val devices = adapter.bondedDevices
                        val printerList = mutableListOf<Map<String, Any>>()
                        for (device in devices) {
                            printerList.add(mapOf(
                                "name" to (device.name ?: "Unknown Device"),
                                "address" to device.address,
                                "type" to device.type
                            ))
                        }
                        result.success(printerList)
                    } catch (e: SecurityException) {
                        result.error("SECURITY_EXCEPTION", e.localizedMessage, null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.localizedMessage, null)
                    }
                }
                "testBluetoothConnection" -> {
                    val address = call.argument<String>("address")
                    if (address.isNullOrEmpty()) {
                        result.success(mapOf("success" to false, "message" to "Printer Bluetooth address is missing"))
                        return@setMethodCallHandler
                    }

                    thread {
                        try {
                            val adapter = BluetoothAdapter.getDefaultAdapter()
                            if (adapter == null || !adapter.isEnabled) {
                                runOnUiThread {
                                    result.success(mapOf("success" to false, "message" to "Bluetooth is disabled"))
                                }
                                return@thread
                            }
                            val device = adapter.getRemoteDevice(address)
                            val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                            adapter.cancelDiscovery()
                            socket.connect()
                            socket.close()
                            runOnUiThread {
                                result.success(mapOf("success" to true, "message" to "Successfully connected to ${device.name ?: address}"))
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.success(mapOf("success" to false, "message" to "Failed to connect: ${e.message ?: "Printer offline or out of range"}"))
                            }
                        }
                    }
                }
                "printBluetoothEscPos" -> {
                    val address = call.argument<String>("address")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (address.isNullOrEmpty()) {
                        result.success(mapOf("success" to false, "message" to "Printer Bluetooth address is empty"))
                        return@setMethodCallHandler
                    }
                    if (bytes == null || bytes.isEmpty()) {
                        result.success(mapOf("success" to false, "message" to "No print data to send"))
                        return@setMethodCallHandler
                    }

                    thread {
                        var socket: BluetoothSocket? = null
                        var outputStream: OutputStream? = null
                        try {
                            val adapter = BluetoothAdapter.getDefaultAdapter()
                            if (adapter == null || !adapter.isEnabled) {
                                runOnUiThread {
                                    result.success(mapOf("success" to false, "message" to "Bluetooth is turned off"))
                                }
                                return@thread
                            }
                            val device = adapter.getRemoteDevice(address)
                            socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                            adapter.cancelDiscovery()
                            socket.connect()

                            outputStream = socket.outputStream
                            outputStream.write(bytes)
                            outputStream.flush()

                            // Short delay to allow thermal printer buffer transmission before closing socket
                            Thread.sleep(150)

                            runOnUiThread {
                                result.success(mapOf("success" to true, "message" to "Printed successfully to ${device.name ?: address}"))
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.success(mapOf("success" to false, "message" to "Bluetooth Print Error: ${e.message ?: "Connection failed"}"))
                            }
                        } finally {
                            try { outputStream?.close() } catch (_: Exception) {}
                            try { socket?.close() } catch (_: Exception) {}
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasBluetoothPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val connectGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
            val scanGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
            connectGranted && scanGranted
        } else {
            val btGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED
            val locGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            btGranted && locGranted
        }
    }

    private fun getRequiredBluetoothPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            )
        } else {
            arrayOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
        }
    }
}
