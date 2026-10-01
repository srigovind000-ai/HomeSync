package com.homesync.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class BudgetPredictor {

    /**
     * Predicts next month's likely spending for each category, based on a
     * weighted moving average of past months. More recent months count
     * more heavily than older ones -- this is plain statistics, not
     * machine learning: no training, no model, just a weighted formula.
     */
    public static Map<String, Double> predictNextMonth(int groupId) throws SQLException {

        // Step 1: fetch every category's monthly totals, most recent month first
        Map<String, List<Double>> monthlyTotalsByCategory = new LinkedHashMap<>();

        String sql = "SELECT c.category_name, "
                   + "  DATE_FORMAT(e.expense_date, '%Y-%m') AS month, "
                   + "  SUM(e.amount) AS month_total "
                   + "FROM expenses e "
                   + "JOIN expense_categories c ON e.category_id = c.category_id "
                   + "WHERE e.group_id = ? "
                   + "GROUP BY c.category_name, month "
                   + "ORDER BY c.category_name, month DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                String category = rs.getString("category_name");
                double monthTotal = rs.getDouble("month_total");

                monthlyTotalsByCategory
                    .computeIfAbsent(category, k -> new ArrayList<>())
                    .add(monthTotal);
            }
        }

        // Step 2: turn each category's month-by-month history into one predicted number
        Map<String, Double> predictions = new LinkedHashMap<>();

        for (Map.Entry<String, List<Double>> entry : monthlyTotalsByCategory.entrySet()) {
            String category = entry.getKey();
            List<Double> monthlyTotals = entry.getValue(); // most recent first

            predictions.put(category, weightedMovingAverage(monthlyTotals));
        }

        return predictions;
    }

    /**
     * Takes up to the last 3 months (most recent first) and applies weights
     * 3, 2, 1 -- the most recent month counts three times as much as the
     * oldest of the three. If fewer than 3 months of history exist, it
     * just uses whatever's available and adjusts the weights accordingly.
     */
    private static double weightedMovingAverage(List<Double> monthlyTotalsMostRecentFirst) {

        int monthsToUse = Math.min(3, monthlyTotalsMostRecentFirst.size());

        double weightedSum = 0;
        double totalWeight = 0;

        for (int i = 0; i < monthsToUse; i++) {
            double weight = monthsToUse - i; // most recent (i=0) gets the highest weight
            weightedSum += monthlyTotalsMostRecentFirst.get(i) * weight;
            totalWeight += weight;
        }

        return totalWeight == 0 ? 0 : weightedSum / totalWeight;
    }
}