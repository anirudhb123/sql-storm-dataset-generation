
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(c.c_customer_sk) AS num_customers
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
),
top_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM 
        sales_data sd
    WHERE 
        sd.total_quantity > 0
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.num_customers,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    cs.total_sales AS customer_sales,
    cs.total_spent AS customer_total_spent
FROM 
    address_info ci
JOIN 
    top_items ti ON ti.total_quantity > 100
JOIN 
    customer_summary cs ON cs.total_sales > 5
WHERE 
    ca_state IS NOT NULL
ORDER BY 
    ci.num_customers DESC, ti.total_sales DESC
LIMIT 50;
