
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        sum(ws_quantity) AS total_quantity,
        sum(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity + COALESCE(SUM(ws_quantity), 0),
        total_sales + COALESCE(SUM(ws_ext_sales_price), 0)
    FROM 
        web_sales s
    JOIN 
        sales_data d ON s.ws_sold_date_sk = d.ws_sold_date_sk AND s.ws_item_sk = d.ws_item_sk
    GROUP BY 
        s.ws_sold_date_sk, s.ws_item_sk, d.total_quantity, d.total_sales
),
customer_aggregates AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
filtered_orders AS (
    SELECT 
        c.c_customer_sk,
        ca.total_quantity,
        ca.total_sales
    FROM 
        customer_aggregates ca
    JOIN 
        sales_data sd ON ca.c_customer_sk = sd.ws_item_sk
    WHERE 
        ca.total_spent > (SELECT AVG(total_spent) FROM customer_aggregates)
)
SELECT 
    c.c_customer_sk,
    MAX(ca.total_sales) AS max_sales,
    MIN(ca.total_sales) AS min_sales,
    COUNT(DISTINCT ca.c_customer_sk) AS unique_customers,
    SUM(COALESCE(sd.total_quantity, 0)) AS total_quantity_sold,
    SUM(CASE 
        WHEN cd.cd_gender = 'F' THEN 1 
        ELSE 0 
        END) AS female_customers,
    SUM(CASE 
        WHEN cd.cd_marital_status = 'M' THEN 1 
        ELSE 0 
        END) AS married_customers,
    SUM(CASE 
        WHEN cd.cd_purchase_estimate IS NULL THEN 1 
        ELSE 0 
        END) AS unestimated_customers
FROM 
    customer_aggregates ca
LEFT JOIN 
    customer_demographics cd ON ca.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    filtered_orders fo ON ca.c_customer_sk = fo.c_customer_sk
GROUP BY 
    ca.c_customer_sk
HAVING 
    COUNT(DISTINCT ca.order_count) > 5
ORDER BY 
    max_sales DESC;
