
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 31
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    SUM(ci.total_spent) AS total_revenue,
    AVG(ci.order_count) AS avg_orders,
    MAX(ci.total_spent) AS max_spent
FROM 
    customer_address a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_info ci ON ci.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    sales_cte s ON s.ws_item_sk = ci.c_customer_sk
WHERE 
    a.ca_state IS NOT NULL
    AND (ci.total_spent > 1000 OR ci.order_count > 5)
GROUP BY 
    a.ca_city, a.ca_state
ORDER BY 
    total_revenue DESC
FETCH FIRST 100 ROWS ONLY;
