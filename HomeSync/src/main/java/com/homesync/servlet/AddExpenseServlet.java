package com.homesync.servlet;

import com.homesync.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;

@WebServlet("/AddExpenseServlet")
public class AddExpenseServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, NumberFormatException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");

        String amountStr = request.getParameter("amount");
        String categoryIdStr = request.getParameter("categoryId");
        String description = request.getParameter("description");
        String expenseDateStr = request.getParameter("expenseDate");
        String groupIdStr = request.getParameter("groupId");

        if (amountStr == null || categoryIdStr == null || expenseDateStr == null || groupIdStr == null) {
            request.setAttribute("errorMessage", "Please fill all required fields.");
            request.getRequestDispatcher("expenses.jsp").forward(request, response);
            return;
        }

        try {
            double amount = Double.parseDouble(amountStr);
            int categoryId = Integer.parseInt(categoryIdStr);
            int groupId = Integer.parseInt(groupIdStr);
            Date expenseDate = Date.valueOf(expenseDateStr); // expects yyyy-MM-dd, which <input type="date"> sends

            String sql = "INSERT INTO expenses (group_id, category_id, paid_by, amount, description, expense_date) "
                       + "VALUES (?, ?, ?, ?, ?, ?)";

            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, groupId);
                stmt.setInt(2, categoryId);
                stmt.setInt(3, userId);
                stmt.setDouble(4, amount);
                stmt.setString(5, description);
                stmt.setDate(6, expenseDate);
                stmt.executeUpdate();
            }

            response.sendRedirect("expenses.jsp");

        } catch (IllegalArgumentException e) {
            request.setAttribute("errorMessage", "Please enter a valid amount and date.");
            request.getRequestDispatcher("expenses.jsp").forward(request, response);
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Could not save the expense. Please try again.");
            request.getRequestDispatcher("expenses.jsp").forward(request, response);
        }
    }
}
