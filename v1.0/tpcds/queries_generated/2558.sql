
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT
        c_customer_id,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_sales
    WHERE total_sales > 0
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.sales_rank,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Performer'
        WHEN tc.sales_rank <= 50 THEN 'Above Average'
        ELSE 'Average Performer'
    END AS performance_category,
    COALESCE(d.d_month_seq, -1) AS month_seq,
    COUNT(DISTINCT wr.wr_order_number) AS web_returns
FROM top_customers tc
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_ship_date_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_id))
LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = tc.c_customer_id
GROUP BY tc.c_customer_id, tc.total_sales, tc.sales_rank, d.d_month_seq
ORDER BY tc.total_sales DESC;
