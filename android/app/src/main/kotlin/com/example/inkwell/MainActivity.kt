package com.example.inkwell

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.URL

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pdf_renderer"
    private var pdfRenderer: PdfRenderer? = null
    private var parcelFileDescriptor: ParcelFileDescriptor? = null
    private var pdfFile: File? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadPdfFromUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        loadPdfFromUrl(url, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "URL is required", null)
                    }
                }
                "renderPdfPage" -> {
                    val pageNumber = call.argument<Int>("pageNumber")
                    val width = call.argument<Double>("width")
                    val height = call.argument<Double>("height")
                    
                    if (pageNumber != null && width != null && height != null) {
                        renderPdfPage(pageNumber, width.toInt(), height.toInt(), result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Page number, width, and height are required", null)
                    }
                }
                "disposePdf" -> {
                    disposePdf()
                    result.success(null)
                }
                "enableSecurityFeatures" -> {
                    enableSecurityFeatures()
                    result.success(null)
                }
                "disableSecurityFeatures" -> {
                    disableSecurityFeatures()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun loadPdfFromUrl(url: String, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Clean up previous PDF
                disposePdf()
                
                // Download PDF to temporary file
                val tempFile = File(cacheDir, "temp_pdf_${System.currentTimeMillis()}.pdf")
                URL(url).openStream().use { input ->
                    FileOutputStream(tempFile).use { output ->
                        input.copyTo(output)
                    }
                }
                
                // Open PDF with PdfRenderer
                pdfFile = tempFile
                parcelFileDescriptor = ParcelFileDescriptor.open(tempFile, ParcelFileDescriptor.MODE_READ_ONLY)
                pdfRenderer = PdfRenderer(parcelFileDescriptor!!)
                
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "totalPages" to pdfRenderer!!.pageCount,
                        "success" to true
                    ))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("PDF_LOAD_ERROR", "Failed to load PDF: ${e.message}", null)
                }
            }
        }
    }
    
    private fun renderPdfPage(pageNumber: Int, width: Int, height: Int, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val renderer = pdfRenderer
                if (renderer == null) {
                    withContext(Dispatchers.Main) {
                        result.error("PDF_NOT_LOADED", "PDF not loaded", null)
                    }
                    return@launch
                }
                
                if (pageNumber < 0 || pageNumber >= renderer.pageCount) {
                    withContext(Dispatchers.Main) {
                        result.error("INVALID_PAGE", "Invalid page number", null)
                    }
                    return@launch
                }
                
                val page = renderer.openPage(pageNumber)

                // Preserve aspect ratio: compute a target size that fits within the requested
                // width and height while keeping the page's intrinsic aspect ratio.
                val pageW = page.width.toFloat()
                val pageH = page.height.toFloat()
                val scale = kotlin.math.min(width / pageW, height / pageH)
                val targetW = kotlin.math.max(1, Math.round(pageW * scale))
                val targetH = kotlin.math.max(1, Math.round(pageH * scale))

                val bitmap = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)

                // Render page to bitmap (dest=null draws to full bitmap with preserved AR)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

                // Convert bitmap to byte array
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                val byteArray = stream.toByteArray()

                // Clean up
                page.close()
                bitmap.recycle()
                stream.close()

                withContext(Dispatchers.Main) {
                    result.success(byteArray)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("RENDER_ERROR", "Failed to render page: ${e.message}", null)
                }
            }
        }
    }
    
    private fun disposePdf() {
        try {
            pdfRenderer?.close()
            parcelFileDescriptor?.close()
            pdfFile?.delete()
        } catch (e: Exception) {
            // Ignore cleanup errors
        } finally {
            pdfRenderer = null
            parcelFileDescriptor = null
            pdfFile = null
        }
    }
    
    private fun enableSecurityFeatures() {
        runOnUiThread {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }
    
    private fun disableSecurityFeatures() {
        runOnUiThread {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
    
    override fun onDestroy() {
        disposePdf()
        super.onDestroy()
    }
}