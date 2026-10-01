package com.homesync.util;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

public class ScoreCalculator {

    /**
     * Fair Contribution Score per member:
     *   (amount they actually paid / their fair share) * 100
     *
     *   100%  = paid exactly their fair share
     *   >100% = overpaid (subsidizing others)
     *   <100% = underpaid (relying on others)
     *
     * We recompute "amount paid" and "fair share" the same way
     * SettlementCalculator does, since a Score is really just
     * another way of looking at the same balance data.
     */
    public static Map<String, Double> calculateFairContributionScores(int groupId) throws SQLException {

        Map<String, Double> balances = SettlementCalculator.calculateBalances(groupId);
        int memberCount = balances.size();

        double totalGroupExpense = getTotalGroupExpense(groupId);
        double fairShare = memberCount == 0 ? 0 : totalGroupExpense / memberCount;

        // balance = amountPaid - fairShare, so amountPaid = balance + fairShare
        Map<String, Double> scores = new LinkedHashMap<>();
        for (Map.Entry<String, Double> entry : balances.entrySet()) {
            double amountPaid = entry.getValue() + fairShare;
            double score = (fairShare == 0) ? 100 : (amountPaid / fairShare) * 100;
            scores.put(entry.getKey(), score);
        }
        return scores;
    }

    /**
     * House Health Score: one number (0-100) for the whole household.
     * The more everyone's balance sits close to zero (already settled),
     * the healthier the household is considered.
     */
    public static double calculateHouseHealthScore(int groupId) throws SQLException {

        Map<String, Double> balances = SettlementCalculator.calculateBalances(groupId);
        double totalGroupExpense = getTotalGroupExpense(groupId);
        int memberCount = balances.size();

        if (memberCount == 0 || totalGroupExpense == 0) {
            return 100; // nothing spent yet = nothing unfair yet
        }

        double fairShare = totalGroupExpense / memberCount;

        // Average of how far each person's balance is from zero
        double totalAbsoluteDeviation = 0;
        for (double bal : balances.values()) {
            totalAbsoluteDeviation += Math.abs(bal);
        }
        double averageDeviation = totalAbsoluteDeviation / memberCount;

        // Express that deviation as a percentage of the fair share,
        // then subtract from 100 -- bigger imbalance = lower health score.
        double deviationPercent = (averageDeviation / fairShare) * 100;

        double healthScore = 100 - deviationPercent;

        // Clamp between 0 and 100 (shouldn't go outside this range, but safe to guard)
        if (healthScore < 0) healthScore = 0;
        if (healthScore > 100) healthScore = 100;

        return healthScore;
    }

    /** Small helper: total money spent by the whole group, straight from the database. */
    private static double getTotalGroupExpense(int groupId) throws SQLException {
        String sql = "SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE group_id = ?";
        try (java.sql.Connection conn = DBConnection.getConnection();
             java.sql.PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            java.sql.ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getDouble("total");
            }
            return 0;
        }
    }
}
