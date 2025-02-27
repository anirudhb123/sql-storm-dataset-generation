
WITH sales_summary AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 AND dd.d_moy IN (11, 12) -- November and December
    GROUP BY ws.web_site_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_id, 
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_summary cs
)
SELECT 
    ss.web_site_id,
    ss.total_quantity,
    ss.total_sales,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_spent
FROM sales_summary ss
INNER JOIN top_customers tc ON ss.total_orders > 100 AND tc.customer_rank <= 10
ORDER BY ss.total_sales DESC, tc.total_spent DESC;
