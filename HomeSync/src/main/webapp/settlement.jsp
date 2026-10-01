<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.SettlementCalculator" %>
<%@ page import="java.util.*" %>
<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    if (session.getAttribute("currentGroupId") == null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    int groupId = (int) session.getAttribute("currentGroupId");
    String groupName = (String) session.getAttribute("currentGroupName");

    Map<String, Double> balances = null;
    List<SettlementCalculator.Settlement> settlements = null;
    Map<String, Integer> memberIds = null;
    String errorMessage = null;
    try {
        balances = SettlementCalculator.calculateBalances(groupId);
        settlements = SettlementCalculator.calculateSettlements(balances);
        memberIds = SettlementCalculator.getMemberIds(groupId);
    } catch (Exception e) {
        e.printStackTrace();
        errorMessage = "Could not calculate settlements right now.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= groupName %> · Settlement · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 760px; margin: 0 auto; padding: 36px 20px 60px; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius); padding: 22px; box-shadow: var(--shadow); margin-bottom: 20px; }
    .card h2 { font-size: 16px; margin: 0 0 16px; }
    .balance-row { display: flex; justify-content: space-between; padding: 9px 0; border-bottom: 1px solid #EFEBE2; font-size: 14px; }
    .balance-row:last-child { border-bottom: none; }
    .positive { color: var(--sage-dark); font-weight: 600; }
    .negative { color: var(--danger); font-weight: 600; }
    .zero { color: var(--ink-soft); }
    .settle-row { padding: 12px 14px; background: var(--sage-light); border-radius: 10px; margin-bottom: 10px;
      font-size: 14.5px; display: flex; justify-content: space-between; align-items: center; }
    .settle-row b { color: var(--sage-dark); }
    .mark-paid-btn { background: var(--ink); color: #fff; border: none; border-radius: 8px;
      padding: 7px 14px; font-size: 12.5px; font-weight: 600; cursor: pointer; font-family: inherit; }
    .mark-paid-btn:hover { background: var(--sage-dark); }
    .empty-state { padding: 20px; text-align: center; color: var(--ink-soft); font-size: 14px; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="expenses.jsp">← Back to expenses</a>
    <h1 style="font-size:22px;"><%= groupName %> — Settlement</h1>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">
      The minimum set of payments needed to clear every balance in this household.
      &middot; <a href="scores.jsp">View household scores →</a>
    </p>

    <% if (errorMessage != null) { %>
      <div class="alert alert-error"><%= errorMessage %></div>
    <% } else { %>

      <div class="card">
        <h2>Who paid what vs. their fair share</h2>
        <% for (Map.Entry<String, Double> entry : balances.entrySet()) {
             double bal = entry.getValue();
             String cssClass = bal > 0.01 ? "positive" : (bal < -0.01 ? "negative" : "zero");
             String label = bal > 0.01 ? "is owed" : (bal < -0.01 ? "owes" : "settled up");
        %>
          <div class="balance-row">
            <span><%= entry.getKey() %></span>
            <span class="<%= cssClass %>"><%= label %> ₹<%= String.format("%.2f", Math.abs(bal)) %></span>
          </div>
        <% } %>
      </div>

      <div class="card">
        <h2>Settlement plan</h2>
        <% if (settlements.isEmpty()) { %>
          <div class="empty-state">Everyone is already settled up 🎉</div>
        <% } else {
             for (SettlementCalculator.Settlement s : settlements) { %>
          <div class="settle-row">
            <span><b><%= s.from %></b> pays <b><%= s.to %></b> ₹<%= String.format("%.2f", s.amount) %></span>
            <form action="MarkAsPaidServlet" method="post" onsubmit="return confirm('Confirm this payment was actually made?');">
              <input type="hidden" name="groupId" value="<%= groupId %>">
              <input type="hidden" name="fromUserId" value="<%= memberIds.get(s.from) %>">
              <input type="hidden" name="toUserId" value="<%= memberIds.get(s.to) %>">
              <input type="hidden" name="amount" value="<%= s.amount %>">
              <button type="submit" class="mark-paid-btn">Mark as Paid</button>
            </form>
          </div>
        <% } } %>
      </div>

    <% } %>

    <% if (errorMessage == null) { %>
      <div class="card">
        <h2>Payment History</h2>
        <%
            String historySql = "SELECT fu.full_name AS from_name, tu.full_name AS to_name, sp.amount, sp.paid_at "
                               + "FROM settlement_payments sp "
                               + "JOIN users fu ON sp.from_user_id = fu.user_id "
                               + "JOIN users tu ON sp.to_user_id = tu.user_id "
                               + "WHERE sp.group_id = ? ORDER BY sp.paid_at DESC";
            boolean hasHistory = false;
            try (java.sql.Connection conn = com.homesync.util.DBConnection.getConnection();
                 java.sql.PreparedStatement histStmt = conn.prepareStatement(historySql)) {
                histStmt.setInt(1, groupId);
                java.sql.ResultSet histRs = histStmt.executeQuery();
                while (histRs.next()) {
                    hasHistory = true;
        %>
          <div class="balance-row">
            <span><%= histRs.getString("from_name") %> → <%= histRs.getString("to_name") %></span>
            <span>₹<%= String.format("%.2f", histRs.getDouble("amount")) %> &middot; <%= histRs.getTimestamp("paid_at") %></span>
          </div>
        <%
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            if (!hasHistory) {
        %>
          <div class="empty-state">No payments recorded yet.</div>
        <%
            }
        %>
      </div>
    <% } %>
  </div>
</body>
</html>
