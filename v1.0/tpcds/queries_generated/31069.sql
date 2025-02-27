
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, 
           0 AS level
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, 
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
monthly_returns AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(sr.sr_return_quantity) AS total_returned,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_returned_per_ticket
    FROM date_dim dd
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = dd.d_date_sk
    GROUP BY dd.d_year, dd.d_month_seq
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_year,
    mr.d_year,
    mr.d_month_seq,
    mr.total_returned,
    mr.total_return_amount,
    tc.customer_name,
    tc.total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Regular Customer'
    END AS customer_status
FROM customer_hierarchy ch
LEFT JOIN monthly_returns mr ON ch.c_birth_year = mr.d_year
LEFT JOIN top_customers tc ON ch.c_customer_sk = tc.c_customer_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = ch.c_customer_sk
GROUP BY ch.c_first_name, ch.c_last_name, ch.c_birth_year, 
         mr.d_year, mr.d_month_seq, tc.customer_name, 
         tc.total_spent
HAVING (mr.total_returned > 0 OR tc.total_spent IS NULL)
ORDER BY ch.c_birth_year, total_orders DESC;
