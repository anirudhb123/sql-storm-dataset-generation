
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 100
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        r.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.order_count
    FROM RankedSales r
    JOIN customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE r.rank <= 10
),
SalesBreakdown AS (
    SELECT
        t.month,
        SUM(CASE WHEN ws_ship_mode_sk = sm_ship_mode_sk THEN total_sales ELSE 0 END) AS total_sales_by_mode,
        SUM(total_sales) AS total_sales_per_month
    FROM (
        SELECT 
            w.ws_sold_date_sk,
            d.d_month_seq AS month,
            r.total_sales
        FROM web_sales w
        JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
        JOIN RankedSales r ON w.ws_bill_customer_sk = r.ws_bill_customer_sk
        WHERE r.rank <= 10
    ) AS monthly_data
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = any(SELECT ws_ship_mode_sk FROM web_sales WHERE ws_bill_customer_sk IN (SELECT ws_bill_customer_sk FROM TopCustomers))
    GROUP BY t.month
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    sb.month,
    sb.total_sales_by_mode,
    sb.total_sales_per_month
FROM TopCustomers tc
JOIN SalesBreakdown sb ON tc.total_sales > 0
ORDER BY sb.month, tc.total_sales DESC;
