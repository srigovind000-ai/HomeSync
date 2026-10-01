<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.BudgetPredictor" %>
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

    Map<String, Double> predictions = null;
    String errorMessage = null;
    try {
        predictions = BudgetPredictor.predictNextMonth(groupId);
    } catch (Exception e) {
        e.printStackTrace();
        errorMessage = "Could not calculate a budget prediction right now.";
    }

    double predictedTotal = 0;
    if (predictions != null) {
        for (double v : predictions.values()) predictedTotal += v;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= groupName %> · Budget Prediction · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 700px; margin: 0 auto; padding: 36px 20px 60px; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius); padding: 24px; box-shadow: var(--shadow); margin-bottom: 20px; }
    .card h2 { font-size: 16px; margin: 0 0 16px; }
    .total-predicted { font-size: 36px; font-weight: 700; font-family: 'Poppins', sans-serif; color: var(--sage-dark); }
    .total-label { color: var(--ink-soft); font-size: 13px; margin-top: 4px; }
    .cat-row { display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid #EFEBE2; }
    .cat-row:last-child { border-bottom: none; }
    .cat-amount { font-weight: 600; }
    .empty-state { padding: 24px; text-align: center; color: var(--ink-soft); font-size: 14px; }
    .note { font-size: 12.5px; color: var(--ink-soft); margin-top: 14px; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="expenses.jsp">← Back to expenses</a>
    <h1 style="font-size:22px;"><%= groupName %> — Budget Prediction</h1>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">
      An estimate of next month's spending, based on your recent months' history.
    </p>

    <% if (errorMessage != null) { %>
      <div class="alert alert-error"><%= errorMessage %></div>
    <% } else if (predictions.isEmpty()) { %>
      <div class="card">
        <div class="empty-state">Not enough expense history yet to predict a budget. Log a few months of expenses first.</div>
      </div>
    <% } else { %>

      <div class="card">
        <h2>Predicted total for next month</h2>
        <div class="total-predicted">₹<%= String.format("%.2f", predictedTotal) %></div>
        <div class="total-label">across all categories</div>
      </div>

      <div class="card">
        <h2>By category</h2>
        <% for (Map.Entry<String, Double> entry : predictions.entrySet()) { %>
          <div class="cat-row">
            <span><%= entry.getKey() %></span>
            <span class="cat-amount">₹<%= String.format("%.2f", entry.getValue()) %></span>
          </div>
        <% } %>
        <div class="note">
          Calculated using a weighted moving average of up to your last 3 months of spending
          per category — recent months count more heavily than older ones. This is a
          statistics-based estimate, not a guarantee.
        </div>
      </div>

    <% } %>
  </div>
</body>
</html>
