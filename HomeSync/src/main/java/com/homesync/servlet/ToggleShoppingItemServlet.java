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

@WebServlet("/ToggleShoppingItemServlet")
public class ToggleShoppingItemServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String itemIdStr = request.getParameter("itemId");

        try {
            int itemId = Integer.parseInt(itemIdStr);

            // NOT is_purchased flips true -> false or false -> true directly in SQL,
            // no need to fetch the current value first and compute the opposite in Java.
            String sql = "UPDATE shopping_list_items SET is_purchased = NOT is_purchased WHERE item_id = ?";

            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, itemId);
                stmt.executeUpdate();
            }

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
        }

        response.sendRedirect("shopping-list.jsp");
    }
}
