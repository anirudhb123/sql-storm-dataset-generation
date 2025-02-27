
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages,
        d.d_year,
        d.d_month_seq
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY c.c_customer_sk, d.d_year, d.d_month_seq
),
AverageMonthlySpend AS (
    SELECT 
        c.customer_sk, 
        AVG(total_spent) AS avg_monthly_spend
    FROM (
        SELECT 
            c.customer_sk, 
            d.d_month_seq,
            total_spent
        FROM CustomerSales c
        JOIN date_dim d ON c.d_year = d.d_year AND c.d_month_seq = d.d_month_seq
    ) AS c
    GROUP BY c.customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        a.avg_monthly_spend
    FROM customer c
    JOIN AverageMonthlySpend a ON c.c_customer_sk = a.customer_sk
    WHERE a.avg_monthly_spend > 500
    ORDER BY a.avg_monthly_spend DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id, 
    tc.avg_monthly_spend
FROM TopCustomers tc
JOIN store s ON s.s_store_sk IN (
    SELECT ss.s_store_sk 
    FROM store_sales ss 
    JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk 
    WHERE ws.ws_bill_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c 
        WHERE c.c_customer_id = tc.c_customer_id
    )
)
ORDER BY tc.avg_monthly_spend DESC;
