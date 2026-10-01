<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.ScoreCalculator" %>
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

    Double houseHealthScore = null;
    Map<String, Double> contributionScores = null;
    String errorMessage = null;
    try {
        houseHealthScore = ScoreCalculator.calculateHouseHealthScore(groupId);
        contributionScores = ScoreCalculator.calculateFairContributionScores(groupId);
    } catch (Exception e) {
        e.printStackTrace();
        errorMessage = "Could not calculate scores right now.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= groupName %> · Scores · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 760px; margin: 0 auto; padding: 36px 20px 60px; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius); padding: 24px; box-shadow: var(--shadow); margin-bottom: 20px; }
    .card h2 { font-size: 16px; margin: 0 0 16px; }
    .health-score { font-size: 44px; font-weight: 700; font-family: 'Poppins', sans-serif; }
    .health-good { color: var(--sage-dark); }
    .health-mid { color: var(--gold); }
    .health-bad { color: var(--danger); }
    .health-label { color: var(--ink-soft); font-size: 13.5px; margin-top: 4px; }
    .contrib-row { display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid #EFEBE2; }
    .contrib-row:last-child { border-bottom: none; }
    .bar-track { background: #EFEBE2; border-radius: 20px; height: 8px; width: 140px; overflow: hidden; }
    .bar-fill { height: 100%; background: var(--sage); }
    .contrib-pct { font-weight: 600; font-size: 13.5px; width: 55px; text-align: right; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="expenses.jsp">← Back to expenses</a>
    <h1 style="font-size:22px;"><%= groupName %> — Household Scores</h1>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">
      A quick read on how fairly and smoothly this household is running.
    </p>

    <% if (errorMessage != null) { %>
      <div class="alert alert-error"><%= errorMessage %></div>
    <% } else {
         String healthClass = houseHealthScore >= 75 ? "health-good" : (houseHealthScore >= 45 ? "health-mid" : "health-bad");
    %>

      <div class="card">
        <h2>House Health Score</h2>
        <div class="health-score <%= healthClass %>"><%= Math.round(houseHealthScore) %></div>
        <div class="health-label">out of 100 — based on how evenly balanced everyone's contributions are right now</div>
      </div>

      <div class="card">
        <h2>Fair Contribution Score</h2>
        <% for (Map.Entry<String, Double> entry : contributionScores.entrySet()) {
             double pct = entry.getValue();
             double barWidth = Math.min(pct, 150); // cap the visual bar so huge overpayments don't break layout
        %>
          <div class="contrib-row">
            <span><%= entry.getKey() %></span>
            <div class="bar-track"><div class="bar-fill" style="width: <%= (barWidth / 150) * 100 %>%;"></div></div>
            <span class="contrib-pct"><%= Math.round(pct) %>%</span>
          </div>
        <% } %>
        <p style="color: var(--ink-soft); font-size: 12.5px; margin-top: 14px;">
          100% = paid exactly their fair share. Above 100% = overpaid (covering others). Below 100% = underpaid.
        </p>
      </div>

    <% } %>
  </div>
</body>
</html>
