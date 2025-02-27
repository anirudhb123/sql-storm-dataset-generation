
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_orders > 5
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM 
        customer_demographics cd
),
top_customers AS (
    SELECT 
        h.c_customer_sk,
        h.c_first_name,
        h.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.purchase_category,
        h.total_orders,
        h.total_spent,
        ROW_NUMBER() OVER (PARTITION BY d.purchase_category ORDER BY h.total_spent DESC) AS rn
    FROM 
        sales_hierarchy h
    JOIN 
        customer_demo d ON h.c_customer_sk = d.cd_demo_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.purchase_category,
    tc.total_orders,
    tc.total_spent
FROM 
    top_customers tc
WHERE 
    tc.rn <= 3
ORDER BY 
    tc.purchase_category, tc.total_spent DESC;
