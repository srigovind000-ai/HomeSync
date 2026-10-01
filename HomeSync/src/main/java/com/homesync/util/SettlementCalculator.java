package com.homesync.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class SettlementCalculator {

    /** One "X pays Y ₹amount" instruction. */
    public static class Settlement {
        public final String from;
        public final String to;
        public final double amount;

        public Settlement(String from, String to, double amount) {
            this.from = from;
            this.to = to;
            this.amount = amount;
        }
    }

    public static Map<String, Double> calculateBalances(int groupId) throws SQLException {

        Map<String, Double> totalPaidByMember = new LinkedHashMap<>();

        String sql = "SELECT u.full_name, u.user_id, "
                   + "  COALESCE(SUM(e.amount), 0) AS total_paid "
                   + "FROM group_members gm "
                   + "JOIN users u ON gm.user_id = u.user_id "
                   + "LEFT JOIN expenses e ON e.paid_by = u.user_id AND e.group_id = gm.group_id "
                   + "WHERE gm.group_id = ? "
                   + "GROUP BY u.user_id, u.full_name";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                totalPaidByMember.put(rs.getString("full_name"), rs.getDouble("total_paid"));
            }
        }

        double totalGroupExpense = 0;
        for (double amountPaid : totalPaidByMember.values()) {
            totalGroupExpense = totalGroupExpense + amountPaid;
        }
        double fairShare = totalPaidByMember.isEmpty() ? 0 : totalGroupExpense / totalPaidByMember.size();

        Map<String, Double> balances = new LinkedHashMap<>();
        for (Map.Entry<String, Double> entry : totalPaidByMember.entrySet()) {
            double balance = entry.getValue() - fairShare;
            balances.put(entry.getKey(), balance);
        }

        // Now adjust for any real-world payments already recorded via "Mark as Paid":
        //   the payer's balance moves UP (they owe less / are owed more, since they already paid)
        //   the receiver's balance moves DOWN (they are owed less, since they already got paid)
        String paymentsSql = "SELECT fu.full_name AS from_name, tu.full_name AS to_name, sp.amount "
                            + "FROM settlement_payments sp "
                            + "JOIN users fu ON sp.from_user_id = fu.user_id "
                            + "JOIN users tu ON sp.to_user_id = tu.user_id "
                            + "WHERE sp.group_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(paymentsSql)) {

            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                String fromName = rs.getString("from_name");
                String toName = rs.getString("to_name");
                double amount = rs.getDouble("amount");

                balances.put(fromName, balances.get(fromName) + amount);
                balances.put(toName, balances.get(toName) - amount);
            }
        }

        return balances;
    }

    /** Maps each member's full name to their user_id -- needed so the UI can
     *  submit a "Mark as Paid" action using real IDs, not just display names. */
    public static Map<String, Integer> getMemberIds(int groupId) throws SQLException {
        Map<String, Integer> memberIds = new LinkedHashMap<>();
        String sql = "SELECT u.user_id, u.full_name FROM group_members gm "
                   + "JOIN users u ON gm.user_id = u.user_id WHERE gm.group_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                memberIds.put(rs.getString("full_name"), rs.getInt("user_id"));
            }
        }
        return memberIds;
    }

    /**
     * Turns balances into the minimum set of payments needed to settle everyone.
     * Repeatedly matches the biggest creditor with the biggest debtor.
     */
    public static List<Settlement> calculateSettlements(Map<String, Double> balances) {

        List<Settlement> settlements = new ArrayList<>();

        // Work on a copy so we don't modify the original balances map
        Map<String, Double> working = new LinkedHashMap<>(balances);

        // A small tolerance for floating-point rounding (e.g. 0.0000001 instead of exactly 0)
        double epsilon = 0.01;

        while (true) {
            String creditor = null; // person owed the most
            String debtor = null;   // person who owes the most
            double maxCredit = epsilon;
            double maxDebit = -epsilon;

            // Find the biggest creditor (highest positive balance)
            // and the biggest debtor (lowest / most negative balance)
            for (Map.Entry<String, Double> entry : working.entrySet()) {
                double bal = entry.getValue();
                if (bal > maxCredit) {
                    maxCredit = bal;
                    creditor = entry.getKey();
                }
                if (bal < maxDebit) {
                    maxDebit = bal;
                    debtor = entry.getKey();
                }
            }

            // If we didn't find both a creditor and a debtor, everyone is settled
            if (creditor == null || debtor == null) {
                break;
            }

            // The amount to settle is the smaller of the two magnitudes
            double amount = Math.min(maxCredit, -maxDebit);
            amount = Math.round(amount * 100.0) / 100.0; // round to 2 decimal places

            settlements.add(new Settlement(debtor, creditor, amount));

            // Update balances: creditor is owed less now, debtor owes less now
            working.put(creditor, working.get(creditor) - amount);
            working.put(debtor, working.get(debtor) + amount);
        }

        return settlements;
    }
}
