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

@WebServlet("/AddShoppingItemServlet")
public class AddShoppingItemServlet extends HttpServlet {

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
        String itemName = request.getParameter("itemName");
        String groupIdStr = request.getParameter("groupId");

        if (itemName == null || itemName.trim().isEmpty() || groupIdStr == null) {
            response.sendRedirect("shopping-list.jsp");
            return;
        }

        try {
            int groupId = Integer.parseInt(groupIdStr);
            String sql = "INSERT INTO shopping_list_items (group_id, item_name, added_by) VALUES (?, ?, ?)";

            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, groupId);
                stmt.setString(2, itemName.trim());
                stmt.setInt(3, userId);
                stmt.executeUpdate();
            }

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
        }

        response.sendRedirect("shopping-list.jsp");
    }
}
