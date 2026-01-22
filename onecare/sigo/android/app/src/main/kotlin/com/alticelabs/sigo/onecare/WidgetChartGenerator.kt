package com.alticelabs.sigo.onecare

import android.content.Context
import android.graphics.*
import kotlin.math.cos
import kotlin.math.sin

/**
 * Generates circular/donut charts for the widget
 */
class WidgetChartGenerator(private val context: Context) {

    data class ChartData(
        val label: String,
        val value: Int,
        val color: Int
    )

    /**
     * Generate a donut chart bitmap
     */
    fun generateDonutChart(
        width: Int,
        height: Int,
        data: List<ChartData>,
        backgroundColor: Int = Color.TRANSPARENT
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Clear background
        canvas.drawColor(backgroundColor)

        val total = data.sumOf { it.value }
        if (total == 0) {
            // Draw empty state
            drawEmptyState(canvas, width, height)
            return bitmap
        }

        val centerX = width / 2f
        val centerY = height / 2f
        val radius = (minOf(width, height) / 2f) * 0.8f
        val donutStrokeWidth = radius * 0.35f
        val chartRadius = radius - donutStrokeWidth / 2

        // Create rect for arc drawing
        val rectF = RectF(
            centerX - chartRadius,
            centerY - chartRadius,
            centerX + chartRadius,
            centerY + chartRadius
        )

        var startAngle = -90f // Start from top

        // Draw each segment
        data.forEach { segment ->
            if (segment.value > 0) {
                val sweepAngle = (segment.value.toFloat() / total) * 360f

                val paint = Paint().apply {
                    isAntiAlias = true
                    style = Paint.Style.STROKE
                    strokeWidth = donutStrokeWidth
                    color = segment.color
                    strokeCap = Paint.Cap.ROUND
                }

                canvas.drawArc(rectF, startAngle, sweepAngle, false, paint)
                startAngle += sweepAngle
            }
        }

        // Draw center circle with total count
        drawCenterText(canvas, centerX, centerY, total.toString(), radius - donutStrokeWidth)

        return bitmap
    }

    /**
     * Generate a pie chart bitmap
     */
    fun generatePieChart(
        width: Int,
        height: Int,
        data: List<ChartData>,
        backgroundColor: Int = Color.TRANSPARENT
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        canvas.drawColor(backgroundColor)

        val total = data.sumOf { it.value }
        if (total == 0) {
            drawEmptyState(canvas, width, height)
            return bitmap
        }

        val centerX = width / 2f
        val centerY = height / 2f
        val radius = (minOf(width, height) / 2f) * 0.85f

        val rectF = RectF(
            centerX - radius,
            centerY - radius,
            centerX + radius,
            centerY + radius
        )

        var startAngle = -90f

        data.forEach { segment ->
            if (segment.value > 0) {
                val sweepAngle = (segment.value.toFloat() / total) * 360f

                val paint = Paint().apply {
                    isAntiAlias = true
                    style = Paint.Style.FILL
                    color = segment.color
                }

                canvas.drawArc(rectF, startAngle, sweepAngle, true, paint)

                // Draw separator line
                val separatorPaint = Paint().apply {
                    isAntiAlias = true
                    style = Paint.Style.STROKE
                    strokeWidth = 2f
                    color = Color.WHITE
                }

                val angle = Math.toRadians((startAngle + sweepAngle).toDouble())
                val endX = centerX + (radius * cos(angle)).toFloat()
                val endY = centerY + (radius * sin(angle)).toFloat()
                canvas.drawLine(centerX, centerY, endX, endY, separatorPaint)

                startAngle += sweepAngle
            }
        }

        // Draw center text with total
        drawCenterCircle(canvas, centerX, centerY, total.toString(), radius * 0.5f)

        return bitmap
    }

    private fun drawEmptyState(canvas: Canvas, width: Int, height: Int) {
        val centerX = width / 2f
        val centerY = height / 2f
        val radius = (minOf(width, height) / 2f) * 0.8f

        // Draw empty circle
        val paint = Paint().apply {
            isAntiAlias = true
            style = Paint.Style.STROKE
            strokeWidth = radius * 0.35f
            color = Color.parseColor("#FFFFFF")
            alpha = 50
        }

        canvas.drawCircle(centerX, centerY, radius - paint.strokeWidth / 2, paint)

        // Draw "No data" text
        val textPaint = Paint().apply {
            isAntiAlias = true
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            textSize = radius * 0.25f
            alpha = 150
        }

        canvas.drawText("No data", centerX, centerY + textPaint.textSize / 3, textPaint)
    }

    private fun drawCenterText(canvas: Canvas, x: Float, y: Float, text: String, maxRadius: Float) {
        val textPaint = Paint().apply {
            isAntiAlias = true
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            textSize = maxRadius * 0.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        canvas.drawText(text, x, y + textPaint.textSize / 3, textPaint)
    }

    private fun drawCenterCircle(canvas: Canvas, x: Float, y: Float, text: String, radius: Float) {
        // Draw white circle background
        val circlePaint = Paint().apply {
            isAntiAlias = true
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        canvas.drawCircle(x, y, radius, circlePaint)

        // Draw total text
        val textPaint = Paint().apply {
            isAntiAlias = true
            color = Color.parseColor("#2196F3")
            textAlign = Paint.Align.CENTER
            textSize = radius * 0.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        canvas.drawText(text, x, y + textPaint.textSize / 3, textPaint)
    }

    companion object {
        // Status colors matching Flutter
        const val COLOR_ACKNOWLEDGED = "#2196F3" // Blue
        const val COLOR_HELD = "#FF9800"         // Orange
        const val COLOR_IN_PROGRESS = "#4CAF50"  // Green
        const val COLOR_PENDING = "#F44336"      // Red

        fun parseColor(colorString: String): Int {
            return try {
                Color.parseColor(colorString)
            } catch (e: Exception) {
                Color.GRAY
            }
        }
    }
}
