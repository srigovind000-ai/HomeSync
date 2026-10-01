<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.DBConnection" %>
<%@ page import="java.sql.*" %>
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
    String errorMessage = (String) request.getAttribute("errorMessage");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= groupName %> · Expenses · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 920px; margin: 0 auto; padding: 36px 20px 60px; }
    .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
    .page-header h1 { font-size: 22px; margin: 0; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .layout { display: grid; grid-template-columns: 300px 1fr; gap: 24px; align-items: start; }
    @media (max-width: 800px) { .layout { grid-template-columns: 1fr; } }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius); padding: 22px; box-shadow: var(--shadow); }
    .card h2 { font-size: 16px; margin: 0 0 16px; }
    select { width: 100%; padding: 12px 14px; border: 1.5px solid #E2DED4; border-radius: 10px;
      font-size: 14.5px; font-family: inherit; background: #fff; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 10px 8px; font-size: 13.5px; border-bottom: 1px solid #EFEBE2; }
    th { color: var(--ink-soft); font-weight: 600; font-size: 12px; text-transform: uppercase; letter-spacing: 0.4px; }
    td.amount { font-weight: 600; text-align: right; }
    .empty-state { padding: 30px; text-align: center; color: var(--ink-soft); font-size: 14px; }
    .total-row { margin-top: 14px; text-align: right; font-size: 15px; font-weight: 600; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="dashboard.jsp">← Back to households</a>
    <div class="page-header">
      <h1><%= groupName %> — Expenses</h1>
      <div style="display:flex; gap:10px;">
        <a href="settlement.jsp" class="btn-primary" style="width:auto; display:inline-block; padding:10px 18px;">View Settlement</a>
        <a href="shopping-list.jsp" class="btn-primary" style="width:auto; display:inline-block; padding:10px 18px; background: var(--sage-dark);">Shopping List</a>
        <a href="bills.jsp" class="btn-primary" style="width:auto; display:inline-block; padding:10px 18px; background: var(--gold);">Bills</a>
        <a href="budget.jsp" class="btn-primary" style="width:auto; display:inline-block; padding:10px 18px; background: var(--ink-soft);">Budget</a>
        <a href="admin-dashboard.jsp" class="btn-primary" style="width:auto; display:inline-block; padding:10px 18px; background: var(--danger);">Admin</a>
        <a href="monthly-reports.jsp" class="btn-primary" style="width:auto; display:inline-block; padding:10px 18px; background: var(--sage);">Reports</a>
      </div>
    </div>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">Every expense logged here is shared across everyone in this household.</p>

    <% if (errorMessage != null) { %>
      <div class="alert alert-error"><%= errorMessage %></div>
    <% } %>

    <div class="layout">

      <div class="card">
        <h2>Add an expense</h2>
        <form action="AddExpenseServlet" method="post">
          <div class="field">
            <label for="amount">Amount (₹)</label>
            <input type="number" step="0.01" min="0.01" id="amount" name="amount" placeholder="e.g. 450.00" required>
          </div>
          <div class="field">
            <label for="categoryId">Category</label>
            <select id="categoryId" name="categoryId" required>
              <%
                  try (Connection conn = DBConnection.getConnection();
                       Statement stmt = conn.createStatement()) {
                      ResultSet catRs = stmt.executeQuery("SELECT category_id, category_name FROM expense_categories ORDER BY category_name");
                      while (catRs.next()) {
              %>
                <option value="<%= catRs.getInt("category_id") %>"><%= catRs.getString("category_name") %></option>
              <%
                      }
                  } catch (SQLException e) {
                      e.printStackTrace();
                  }
              %>
            </select>
          </div>
          <div class="field">
            <label for="description">Description</label>
            <input type="text" id="description" name="description" placeholder="e.g. Electricity bill - June">
          </div>
          <div class="field">
            <label for="expenseDate">Date</label>
            <input type="date" id="expenseDate" name="expenseDate" required>
          </div>
          <input type="hidden" name="groupId" value="<%= groupId %>">
          <button type="submit" class="btn-primary">Add Expense</button>
        </form>
      </div>

      <div class="card">
        <h2>Recent expenses</h2>
        <%
            String sql = "SELECT e.amount, e.description, e.expense_date, c.category_name, u.full_name "
                       + "FROM expenses e "
                       + "JOIN expense_categories c ON e.category_id = c.category_id "
                       + "JOIN users u ON e.paid_by = u.user_id "
                       + "WHERE e.group_id = ? "
                       + "ORDER BY e.expense_date DESC, e.expense_id DESC";
            boolean hasExpenses = false;
            double total = 0;
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, groupId);
                ResultSet rs = pstmt.executeQuery();
        %>
        <table>
          <tr><th>Date</th><th>Category</th><th>Description</th><th>Paid By</th><th>Amount</th></tr>
          <%
              while (rs.next()) {
                  hasExpenses = true;
                  total += rs.getDouble("amount");
          %>
          <tr>
            <td><%= rs.getDate("expense_date") %></td>
            <td><%= rs.getString("category_name") %></td>
            <td><%= rs.getString("description") != null ? rs.getString("description") : "—" %></td>
            <td><%= rs.getString("full_name") %></td>
            <td class="amount">₹<%= String.format("%.2f", rs.getDouble("amount")) %></td>
          </tr>
          <%
              }
          %>
        </table>
        <%
            } catch (SQLException e) {
                e.printStackTrace();
        %>
          <div class="alert alert-error">Could not load expenses right now.</div>
        <%
            }
            if (!hasExpenses) {
        %>
          <div class="empty-state">No expenses logged yet — add the first one.</div>
        <%
            } else {
        %>
          <div class="total-row">Total: ₹<%= String.format("%.2f", total) %></div>
        <%
            }
        %>
      </div>

    </div>
  </div>
</body>
</html>
