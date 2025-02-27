
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        1 AS level
    FROM 
        item i
    WHERE 
        i.i_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws)
    
    UNION ALL
    
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ih.level + 1
    FROM 
        item i
    JOIN 
        item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
)
SELECT 
    ca.c_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS average_sales_price,
    COUNT(DISTINCT wp.wp_web_page_id) AS pages_visited,
    MAX(DATE(d.d_date)) AS last_purchase_date,
    CASE 
        WHEN SUM(ws.ws_sales_price) IS NULL THEN 'No Sales'
        ELSE 
            CASE 
                WHEN SUM(ws.ws_sales_price) > 100000 THEN 'High Revenue'
                WHEN SUM(ws.ws_sales_price) BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
                ELSE 'Low Revenue' 
            END
    END AS revenue_category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    item_hierarchy ih ON ws.ws_item_sk = ih.i_item_sk
GROUP BY 
    ca.c_city
HAVING 
    customer_count > 10
ORDER BY 
    total_net_profit DESC
LIMIT 10;
