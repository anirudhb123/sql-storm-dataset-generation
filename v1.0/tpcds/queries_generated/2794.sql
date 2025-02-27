
WITH sales_summary AS (
    SELECT
        ws.web_site_sk,
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 3
    )
    GROUP BY ws.web_site_sk, w.w_warehouse_name
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE
            WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 'Married Female'
            WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'S' THEN 'Single Female'
            WHEN cd.cd_gender = 'M' AND cd.marital_status = 'M' THEN 'Married Male'
            ELSE 'Single Male'
        END AS marital_gender_category,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT
        cu.c_customer_sk,
        cu.marital_gender_category,
        cu.total_net_profit,
        RANK() OVER (PARTITION BY cu.marital_gender_category ORDER BY cu.total_net_profit DESC) AS rank
    FROM customer_summary cu
)
SELECT
    s.web_site_sk,
    s.w_warehouse_name,
    tc.marital_gender_category,
    tc.total_net_profit
FROM sales_summary s
JOIN top_customers tc ON s.total_net_profit = tc.total_net_profit
WHERE tc.rank <= 5
ORDER BY s.total_quantity DESC, tc.total_net_profit DESC;
