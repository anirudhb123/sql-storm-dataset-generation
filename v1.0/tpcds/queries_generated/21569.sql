
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_returns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returned
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
net_customer_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_spent, 0) - COALESCE(cr.total_returned, 0) AS net_spent,
        cs.order_count
    FROM customer_sales cs
    LEFT JOIN customer_returns cr ON cs.c_customer_sk = cr.cr_returning_customer_sk
),
date_filter AS (
    SELECT 
        d.d_date_sk,
        d.d_date_id
    FROM date_dim d
    WHERE d.d_year = 2023 AND d.d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d.d_week_seq BETWEEN 7 AND 14)
)
SELECT 
    ncs.c_customer_sk,
    ncs.c_first_name,
    ncs.c_last_name,
    ncs.net_spent,
    ncs.order_count,
    d.d_date_id AS sale_period
FROM net_customer_sales ncs
JOIN date_filter d ON d.d_date_sk IN (
    SELECT DISTINCT ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = ncs.c_customer_sk
)
WHERE ncs.net_spent > (SELECT AVG(total_spent) FROM customer_sales)
ORDER BY ncs.net_spent DESC
FETCH FIRST 10 ROWS ONLY;
