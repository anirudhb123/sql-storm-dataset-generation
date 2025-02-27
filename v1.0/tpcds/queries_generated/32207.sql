
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
    HAVING 
        total_quantity > 10
),
top_sales AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales) AS sales
    FROM 
        sales_summary
    GROUP BY 
        ws_item_sk
    ORDER BY 
        sales DESC
    LIMIT 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS rn
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IS NOT NULL
),
ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        DENSE_RANK() OVER (ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_birth_year IS NOT NULL
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    ts.sales,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ts.sales DESC) AS city_sales_rank
FROM 
    ranked_customers c
JOIN 
    customer_addresses ca ON ca.ca_address_id = c.c_customer_id
JOIN 
    top_sales ts ON ts.ws_item_sk = c.c_customer_sk
WHERE 
    c.c_email_address IS NOT NULL
    AND ca.rn <= 5
ORDER BY 
    ca.ca_state, city_sales_rank;
