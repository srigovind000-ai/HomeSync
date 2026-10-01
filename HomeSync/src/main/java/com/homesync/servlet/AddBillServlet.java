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
import java.sql.PreparedStatement;
import java.sql.SQLException;

@WebServlet("/AddBillServlet")
public class AddBillServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        String billName = request.getParameter("billName");
        String amountStr = request.getParameter("amount");
        String dueDayStr = request.getParameter("dueDay");
        String groupIdStr = request.getParameter("groupId");

        if (billName == null || billName.trim().isEmpty() || dueDayStr == null || groupIdStr == null) {
            response.sendRedirect("bills.jsp");
            return;
        }

        try {
            int groupId = Integer.parseInt(groupIdStr);
            int dueDay = Integer.parseInt(dueDayStr);

            if (dueDay < 1 || dueDay > 31) {
                response.sendRedirect("bills.jsp");
                return;
            }

            // Amount is optional -- treat a blank field as 0 rather than failing
            double amount = (amountStr == null || amountStr.trim().isEmpty()) ? 0 : Double.parseDouble(amountStr);

            String sql = "INSERT INTO recurring_bills (group_id, bill_name, amount, due_day, created_by) "
                       + "VALUES (?, ?, ?, ?, ?)";

            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, groupId);
                stmt.setString(2, billName.trim());
                stmt.setDouble(3, amount);
                stmt.setInt(4, dueDay);
                stmt.setInt(5, userId);
                stmt.executeUpdate();
            }

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
        }

        response.sendRedirect("bills.jsp");
    }
}
