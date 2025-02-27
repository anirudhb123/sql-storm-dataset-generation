
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank = 1
),
sales_summary AS (
    SELECT 
        t.ws_item_sk,
        SUM(t.ws_sales_price) AS total_sales,
        COUNT(*) AS total_orders
    FROM 
        top_sales t
    GROUP BY 
        t.ws_item_sk
)

SELECT 
    ca.ca_city,
    SUM(ss.total_sales) AS total_sales_in_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_item_sk IN (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_addr_sk = ca.ca_address_sk
    )
WHERE 
    ca.ca_country IS NULL OR ca.ca_country <> 'UNKNOWN'
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ss.total_sales) > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    total_sales_in_city DESC
LIMIT 10;
