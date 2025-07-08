
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(NULLIF(i.i_size, ''), 'N/A') AS size_category,
        i.i_category,
        1 AS level
    FROM item i
    WHERE i.i_current_price IS NOT NULL
    UNION ALL
    SELECT 
        ih.i_item_sk,
        ih.i_item_desc,
        ih.i_current_price * 0.9 AS discounted_price,
        ih.i_brand,
        'Category: ' || ih.i_category AS size_category,
        ih.i_category,
        ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk
    WHERE ih.level < 3
)
SELECT 
    c.c_customer_id,
    COALESCE(NULLIF(c.c_first_name, ''), 'Unknown') AS customer_first_name,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(CASE WHEN ws.ws_sales_price > 100 THEN ws.ws_sales_price ELSE NULL END) AS high_value_avg,
    STRING_AGG(DISTINCT CONCAT(ih.i_item_desc, ' ($', ih.i_current_price, ')'), '; ') AS purchased_items
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN item_hierarchy ih ON ws.ws_item_sk = ih.i_item_sk
WHERE 
    (c.c_birth_year BETWEEN 1970 AND 2000) AND
    (ca.ca_state IS NULL OR ca.ca_state IN ('CA', 'TX', 'NY')) AND
    (ih.size_category IS NOT NULL AND LENGTH(ih.size_category) < 20)
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    ca.ca_city, 
    ih.i_item_desc, 
    ih.i_current_price
HAVING 
    SUM(ws.ws_sales_price) > 500
ORDER BY 
    total_sales DESC,
    order_count DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM customer WHERE c_birth_month IS NULL) % 50;
