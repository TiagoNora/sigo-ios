package com.alticelabs.sigo.onecare

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.home_widget_layout).apply {

                    // Check if widget is loading
                    val isLoading = widgetData.getBoolean("widget_loading", false)

                    // Show/hide loading overlay
                    if (isLoading) {
                        setViewVisibility(R.id.widget_loading_overlay, android.view.View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.widget_loading_overlay, android.view.View.GONE)
                    }

                    // Get ticket statistics from Flutter
                    val acknowledged = widgetData.getInt("ticket_acknowledged", 0)
                    val held = widgetData.getInt("ticket_held", 0)
                val inProgress = widgetData.getInt("ticket_in_progress", 0)
                val pending = widgetData.getInt("ticket_pending", 0)
                val total = widgetData.getInt("ticket_total", 0)
                val lastUpdateRaw = widgetData.getString("ticket_last_update", null)
                val lastUpdateText = formatLastUpdate(context, lastUpdateRaw)

                // Update legend TextViews
                setTextViewText(R.id.ticket_acknowledged, acknowledged.toString())
                setTextViewText(R.id.ticket_held, held.toString())
                setTextViewText(R.id.ticket_in_progress, inProgress.toString())
                setTextViewText(R.id.ticket_pending, pending.toString())
                setTextViewText(
                    R.id.ticket_total,
                    context.getString(R.string.widget_total_format, total)
                )
                setTextViewText(R.id.widget_last_update, lastUpdateText)

                    // Create intent to launch the app
                    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                        ?: Intent(context, MainActivity::class.java).apply {
                            action = Intent.ACTION_MAIN
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                    launchIntent.apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                        putExtra("openFromWidget", true)
                    }

                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }

                val pendingIntent = PendingIntent.getActivity(
                    context,
                    widgetId,
                    launchIntent,
                    flags
                )

                // Make the entire widget clickable
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Refresh button triggers background update without opening the app
                val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("sigoonecare://refresh")
                )
                setOnClickPendingIntent(R.id.widget_refresh, refreshIntent)
            }

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                Log.e("HomeWidgetProvider", "Widget update failed", e)
                // Avoid crashing the widget host; keep last valid RemoteViews if any.
            }
        }
    }

    private fun generateTicketChart(
        context: Context,
        acknowledged: Int,
        held: Int,
        inProgress: Int,
        pending: Int
    ): Bitmap {
        val chartGenerator = WidgetChartGenerator(context)

        // Prepare chart data with colors
        val chartData = listOf(
            WidgetChartGenerator.ChartData(
                "Acknowledged",
                acknowledged,
                WidgetChartGenerator.parseColor(WidgetChartGenerator.COLOR_ACKNOWLEDGED)
            ),
            WidgetChartGenerator.ChartData(
                "Held",
                held,
                WidgetChartGenerator.parseColor(WidgetChartGenerator.COLOR_HELD)
            ),
            WidgetChartGenerator.ChartData(
                "In Progress",
                inProgress,
                WidgetChartGenerator.parseColor(WidgetChartGenerator.COLOR_IN_PROGRESS)
            ),
            WidgetChartGenerator.ChartData(
                "Pending",
                pending,
                WidgetChartGenerator.parseColor(WidgetChartGenerator.COLOR_PENDING)
            )
        )

        // Generate donut chart (change to generatePieChart for pie style)
        return chartGenerator.generateDonutChart(
            width = 300,
            height = 300,
            data = chartData
        )
    }

    private fun formatLastUpdate(context: Context, isoValue: String?): String {
        if (isoValue.isNullOrBlank()) {
            return context.getString(R.string.widget_last_update_default)
        }

        return try {
            val instant = Instant.parse(isoValue)
            val formatter = DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT)
                .withLocale(context.resources.configuration.locales[0])
                .withZone(ZoneId.systemDefault())
            context.getString(R.string.widget_last_update_format, formatter.format(instant))
        } catch (e: Exception) {
            context.getString(R.string.widget_last_update_default)
        }
    }
}
