
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
),
top_sales AS (
    SELECT 
        r.ws_order_number, 
        r.ws_item_sk, 
        r.ws_sales_price, 
        r.ws_quantity
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank = 1
),
total_sales AS (
    SELECT 
        ts.ws_item_sk, 
        SUM(ts.ws_sales_price * ts.ws_quantity) AS total_sales_value
    FROM 
        top_sales ts
    GROUP BY 
        ts.ws_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    MAX(ts.total_sales_value) AS max_sales,
    AVG(ts.total_sales_value) AS avg_sales_value,
    STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_color, ')'), ', ') AS item_descriptions
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    total_sales ts ON ts.ws_item_sk IN (SELECT cr_item_sk FROM catalog_returns WHERE cr_returned_date_sk IS NOT NULL)
LEFT JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND ca.ca_country != 'USA'
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    max_sales DESC;
