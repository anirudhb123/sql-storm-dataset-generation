
WITH RECURSIVE category_hierarchy AS (
    SELECT i_category_id, i_category, 1 AS level
    FROM item
    WHERE i_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_sold_date_sk = (
        SELECT MAX(cs_sold_date_sk) FROM catalog_sales))
    UNION ALL
    SELECT i_category_id, i_category, ch.level + 1
    FROM item i
    JOIN category_hierarchy ch ON i_category_id = i_category_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 1000 THEN 'High Value'
        WHEN SUM(ws.ws_sales_price) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category,
    STRING_AGG(DISTINCT i_brand) AS brands_in_category
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN category_hierarchy ch ON i.i_category_id = ch.i_category_id
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY total_sales DESC
LIMIT 10;
