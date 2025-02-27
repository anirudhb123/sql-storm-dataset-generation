
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk,
        total_sales,
        order_count
    FROM 
        sales_cte
    WHERE 
        sales_rank <= 10
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
customer_ranks AS (
    SELECT 
        c.c_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) as gender_rank
    FROM 
        customer_stats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        total_orders > 5
    HAVING 
        SUM(total_spent) > 1000
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state = 'CA'
    AND EXISTS (SELECT 1 FROM customer_ranks cr WHERE cr.c_customer_sk = c.c_customer_sk AND cr.gender_rank <= 5)
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
