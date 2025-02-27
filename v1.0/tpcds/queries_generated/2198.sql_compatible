
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id, ws.ws_sold_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS customer_rank
    FROM customer_summary cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_profit > (SELECT AVG(total_profit) FROM customer_summary)
)
SELECT 
    hvc.c_customer_id,
    hvc.total_profit,
    s.total_quantity,
    s.total_profit AS web_sales_profit,
    CASE 
        WHEN s.total_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM high_value_customers hvc
FULL OUTER JOIN sales_data s ON hvc.c_customer_id = s.web_site_id
WHERE hvc.customer_rank <= 10
ORDER BY hvc.total_profit DESC, s.total_profit DESC;
