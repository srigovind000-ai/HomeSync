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

@WebServlet("/MarkAsPaidServlet")
public class MarkAsPaidServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String groupIdStr = request.getParameter("groupId");
        String fromUserIdStr = request.getParameter("fromUserId");
        String toUserIdStr = request.getParameter("toUserId");
        String amountStr = request.getParameter("amount");

        try {
            int groupId = Integer.parseInt(groupIdStr);
            int fromUserId = Integer.parseInt(fromUserIdStr);
            int toUserId = Integer.parseInt(toUserIdStr);
            double amount = Double.parseDouble(amountStr);

            String sql = "INSERT INTO settlement_payments (group_id, from_user_id, to_user_id, amount) "
                       + "VALUES (?, ?, ?, ?)";

            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, groupId);
                stmt.setInt(2, fromUserId);
                stmt.setInt(3, toUserId);
                stmt.setDouble(4, amount);
                stmt.executeUpdate();
            }

            response.sendRedirect("settlement.jsp");

        } catch (NumberFormatException e) {
            response.sendRedirect("settlement.jsp");
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("settlement.jsp");
        }
    }
}
