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

@WebServlet("/DeleteBillServlet")
public class DeleteBillServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String billIdStr = request.getParameter("billId");

        try {
            int billId = Integer.parseInt(billIdStr);
            String sql = "DELETE FROM recurring_bills WHERE bill_id = ?";

            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, billId);
                stmt.executeUpdate();
            }

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
        }

        response.sendRedirect("bills.jsp");
    }
}
