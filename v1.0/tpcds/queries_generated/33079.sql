
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.bill_customer_sk, ws.ws_item_sk
), customer_stats AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), top_customers AS (
    SELECT 
        cs.bill_customer_sk,
        COUNT(DISTINCT cs.ws_item_sk) AS items_purchased,
        SUM(cs.total_profit) AS total_profit
    FROM 
        sales_data cs
    GROUP BY 
        cs.bill_customer_sk
    ORDER BY 
        total_profit DESC
    LIMIT 100
)
SELECT 
    tc.bill_customer_sk,
    cs.gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.cd_credit_rating,
    tc.items_purchased,
    tc.total_profit,
    ca.ca_city,
    CASE 
        WHEN cs.cd_purchase_estimate IS NULL THEN 'No Estimate'
        WHEN cs.cd_purchase_estimate > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_band
FROM 
    top_customers tc
JOIN 
    customer_stats cs ON tc.bill_customer_sk = cs.c_customer_sk
LEFT JOIN 
    customer_address ca ON cs.ca_city = ca.ca_city
WHERE 
    cs.city_rank <= 10
ORDER BY 
    tc.total_profit DESC;
