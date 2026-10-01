package com.homesync.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/SelectGroupServlet")
public class SelectGroupServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String groupIdParam = request.getParameter("groupId");
        String groupName = request.getParameter("groupName");

        if (groupIdParam != null) {
            session.setAttribute("currentGroupId", Integer.parseInt(groupIdParam));
            session.setAttribute("currentGroupName", groupName);
        }

        response.sendRedirect("expenses.jsp");
    }
}
