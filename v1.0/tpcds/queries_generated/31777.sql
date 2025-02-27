
WITH RECURSIVE sales_ranking AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(SUM(web_sales.ws_sales_price), 0) AS total_sales_price,
        COUNT(DISTINCT web_sales.ws_order_number) AS order_count
    FROM 
        item
    LEFT JOIN 
        web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_product_name
    HAVING 
        COUNT(DISTINCT web_sales.ws_order_number) > 10
),
customer_counts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address 
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_state
)
SELECT 
    c.ca_state,
    tc.i_product_name,
    tc.total_sales_price,
    tc.order_count,
    cc.customer_count,
    COALESCE(tc.total_sales_price / NULLIF(cc.customer_count, 0), 0) AS avg_sales_per_customer
FROM 
    customer_counts c
JOIN 
    top_items tc ON c.ca_state = 'CA'
LEFT JOIN 
    sales_ranking sr ON tc.i_item_id = sr.ws_item_sk
WHERE 
    sr.rank <= 5
ORDER BY 
    avg_sales_per_customer DESC;
