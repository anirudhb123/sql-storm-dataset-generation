
WITH sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.total_sales) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        sales_summary ws 
    JOIN 
        customer_info c ON ws.ws_item_sk IN (
            SELECT DISTINCT ws_item_sk 
            FROM web_sales 
            WHERE ws_bill_customer_sk IS NOT NULL
        )
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.total_sales) > 1000
)
SELECT 
    c.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    hvc.total_spent,
    hvc.order_count,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY hvc.total_spent DESC) AS rank
FROM 
    high_value_customers hvc
JOIN 
    customer_info ci ON hvc.c_customer_sk = ci.c_customer_sk
LEFT JOIN 
    date_dim dd ON dd.d_date_sk = hvc.c_customer_sk
WHERE 
    dd.d_year = 2023
ORDER BY 
    hvc.total_spent DESC
LIMIT 50;
