
WITH RECURSIVE customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        dvd.d_year,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dvd ON c.c_first_sales_date_sk = dvd.d_date_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
combined_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        ss.total_profit,
        ss.total_orders,
        ss.avg_sales_price
    FROM 
        customer_summary cs
    LEFT JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        cs.purchase_rank = 1
)
SELECT 
    c.c_customer_id,
    COALESCE(cs.cd_gender, 'Unknown') AS gender,
    CASE 
        WHEN cs.cd_marital_status IS NULL THEN 'Single'
        ELSE cs.cd_marital_status
    END as marital_status,
    cs.total_profit,
    cs.total_orders,
    CASE 
        WHEN cs.total_orders IS NULL OR cs.total_orders = 0 THEN 0
        ELSE cs.total_profit / NULLIF(cs.total_orders, 0)
    END AS profit_per_order,
    TRIM(CONCAT('Customer ID: ', cs.c_customer_id, ' | Total Profit: $', COALESCE(CAST(cs.total_profit AS VARCHAR), '0'), ' | Avg Sales Price: $', COALESCE(CAST(cs.avg_sales_price AS VARCHAR), '0'))) ) AS report
FROM 
    combined_summary cs
WHERE 
    (EXISTS (SELECT 1 FROM customer_demographics cd 
              WHERE cd.cd_purchase_estimate > 1000 
              AND cd.cd_demo_sk = cs.c_customer_id ) OR cs.total_profit > 0)
ORDER BY 
    COALESCE(cs.total_profit, 0) DESC
LIMIT 10 OFFSET 5;
