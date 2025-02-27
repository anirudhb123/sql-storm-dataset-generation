
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_ext_sales_price,
        ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_ext_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_average AS (
    SELECT 
        cd_demo_sk,
        AVG(ws_ext_sales_price) AS avg_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk
),
top_items AS (
    SELECT 
        i_item_sk,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        i_item_sk
    HAVING 
        SUM(ws_quantity) > 1000
),
item_details AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_category
    FROM 
        item
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    r_sales.ws_ext_sales_price,
    r_sales.price_rank,
    COALESCE(c_avg.avg_sales, 0) AS avg_customer_sales,
    id.i_product_name,
    id.i_category
FROM 
    ranked_sales r_sales
JOIN 
    customer c ON r_sales.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_average c_avg ON c.c_current_cdemo_sk = c_avg.cd_demo_sk
JOIN 
    top_items ti ON r_sales.ws_item_sk = ti.i_item_sk
JOIN 
    item_details id ON ti.i_item_sk = id.i_item_sk
WHERE 
    r_sales.price_rank <= 5
    AND ca.ca_state IS NOT NULL
ORDER BY 
    r_sales.ws_ext_sales_price DESC;
