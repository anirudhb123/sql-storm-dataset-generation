
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN ca.ca_zip IS NULL THEN 'ZIP code not provided' 
            ELSE ca.ca_zip 
        END AS zip_code
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws.ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.gender,
        cd.marital_status,
        cd.purchase_estimate,
        cd.city,
        cd.state,
        sd.total_profit,
        sd.total_orders,
        sd.avg_sales_price
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 50000 
        AND sd.total_profit IS NOT NULL
),
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY gender ORDER BY total_profit DESC) AS profit_rank
    FROM 
        high_value_customers
)
SELECT 
    rc.c_customer_sk,
    rc.gender,
    rc.marital_status,
    rc.total_profit,
    rc.total_orders,
    rc.avg_sales_price,
    rc.profit_rank
FROM 
    ranked_customers rc
WHERE 
    rc.profit_rank <= 10
ORDER BY 
    rc.gender, rc.total_profit DESC
UNION ALL
SELECT 
    -1 AS c_customer_sk,
    NULL AS gender,
    NULL AS marital_status,
    NULL AS total_profit,
    NULL AS total_orders,
    NULL AS avg_sales_price,
    NULL AS profit_rank
WHERE 
    NOT EXISTS (SELECT 1 FROM ranked_customers)
ORDER BY 
    c_customer_sk;
