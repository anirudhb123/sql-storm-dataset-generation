
WITH sales_summary AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY 
        ws_ship_mode_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ss.net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.total_profit,
        ROW_NUMBER() OVER (ORDER BY ci.total_profit DESC) AS rn
    FROM 
        customer_info ci
    WHERE 
        ci.total_profit > 0
)
SELECT 
    ts.c_customer_sk,
    ts.cd_gender,
    ts.cd_marital_status,
    ts.cd_purchase_estimate,
    ts.cd_credit_rating,
    ts.total_profit,
    ss.total_quantity,
    ss.total_revenue,
    ss.total_orders
FROM 
    top_customers ts
JOIN 
    sales_summary ss ON ts.c_customer_sk = ss.ws_ship_mode_sk
WHERE 
    ts.rn <= 10
ORDER BY 
    ts.total_profit DESC;
