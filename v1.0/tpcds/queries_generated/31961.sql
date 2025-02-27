
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        0 AS level
    FROM 
        item i
    WHERE 
        i.i_item_sk IS NOT NULL

    UNION ALL

    SELECT 
        ih.i_item_sk,
        ih.i_item_id,
        CONCAT(ih.i_product_name, ' -> ', i.i_product_name),
        ih.i_current_price * 0.9 AS discounted_price,
        level + 1
    FROM 
        ItemHierarchy ih
    JOIN 
        item i ON ih.i_item_sk = i.i_item_sk AND ih.level < 3
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid) AS average_payment,
    MAX(ws.ws_sales_price) AS highest_price,
    MIN(ws.ws_sales_price) AS lowest_price,
    item_hierarchy.i_item_id,
    item_hierarchy.i_product_name,
    item_hierarchy.discounted_price
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    ItemHierarchy item_hierarchy ON ws.ws_item_sk = item_hierarchy.i_item_sk
WHERE 
    ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    AND (ca.ca_city IS NOT NULL OR ca.ca_city = 'Unknown')
GROUP BY 
    ca.ca_city, item_hierarchy.i_item_id, item_hierarchy.i_product_name, item_hierarchy.discounted_price
HAVING 
    total_profit > 1000
ORDER BY 
    unique_customers DESC, total_profit ASC;
