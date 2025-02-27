
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid) AS total_web_spent,
        AVG(ws.ws_net_paid) AS avg_web_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
date_range AS (
    SELECT 
        d.d_date_sk,
        d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    dr.d_year,
    dr.d_date_sk,
    cs.total_web_orders,
    cs.total_web_spent,
    cs.avg_web_spent,
    RANK() OVER (PARTITION BY dr.d_year ORDER BY cs.total_web_spent DESC) AS spending_rank
FROM customer_stats cs
JOIN date_range dr ON dr.d_year IN (2022, 2023)
WHERE cs.total_web_orders > 0
ORDER BY dr.d_year, spending_rank;
