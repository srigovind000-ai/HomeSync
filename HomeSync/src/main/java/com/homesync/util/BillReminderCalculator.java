package com.homesync.util;

import java.time.LocalDate;
import java.time.YearMonth;

public class BillReminderCalculator {

    /**
     * Given a "due day of the month" (e.g. 5 = the 5th of every month),
     * returns how many days from TODAY until that bill is next due.
     *
     * Examples (assuming today is the 20th of a 30-day month):
     *   dueDay = 25  -> returns 5   (later this month)
     *   dueDay = 10  -> returns 20  (already passed this month, so next month's 10th)
     *   dueDay = 20  -> returns 0   (due today)
     */
    public static int daysUntilDue(int dueDay) {
        LocalDate today = LocalDate.now();

        // Clamp dueDay to the current month's actual length, in case someone
        // set due_day = 31 but this month only has 30 (or 28/29) days.
        int lastDayOfThisMonth = YearMonth.from(today).lengthOfMonth();
        int safeDueDayThisMonth = Math.min(dueDay, lastDayOfThisMonth);

        LocalDate dueDateThisMonth = today.withDayOfMonth(safeDueDayThisMonth);

        if (!dueDateThisMonth.isBefore(today)) {
            // Due date this month hasn't happened yet (or is today)
            return (int) java.time.temporal.ChronoUnit.DAYS.between(today, dueDateThisMonth);
        } else {
            // Already passed this month -- calculate for next month instead
            LocalDate nextMonth = today.plusMonths(1);
            int lastDayOfNextMonth = YearMonth.from(nextMonth).lengthOfMonth();
            int safeDueDayNextMonth = Math.min(dueDay, lastDayOfNextMonth);
            LocalDate dueDateNextMonth = nextMonth.withDayOfMonth(safeDueDayNextMonth);
            return (int) java.time.temporal.ChronoUnit.DAYS.between(today, dueDateNextMonth);
        }
    }

    /** A bill is considered "upcoming" and worth alerting about if due within this many days. */
    public static final int ALERT_WINDOW_DAYS = 3;

    public static boolean isUpcoming(int dueDay) {
        int daysLeft = daysUntilDue(dueDay);
        return daysLeft <= ALERT_WINDOW_DAYS;
    }
}
