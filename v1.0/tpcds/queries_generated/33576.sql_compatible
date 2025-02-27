
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.order_count,
        cs.total_spent
    FROM customer_stats cs
    WHERE cs.total_spent > (
        SELECT AVG(total_spent) FROM customer_stats
    )
)
SELECT 
    t.customer_gender,
    COUNT(*) AS number_of_customers,
    AVG(t.total_spent) AS average_spending
FROM (
    SELECT 
        tc.cd_gender AS customer_gender,
        tc.total_spent
    FROM top_customers tc
    JOIN sales_summary ss ON tc.c_customer_sk = ss.web_site_sk
) t
GROUP BY t.customer_gender
ORDER BY number_of_customers DESC
LIMIT 10;
