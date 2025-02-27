
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales
    WHERE ws_sales_price > 50
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number DESC) AS rn
    FROM catalog_sales
    WHERE cs_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
)
SELECT 
    COALESCE(wp.wp_web_page_id, cps.cp_catalog_page_id) AS page_id,
    SUM(sh.ws_quantity + sh.cs_quantity) AS total_quantity_sold,
    SUM(sh.ws_sales_price + sh.cs_sales_price) AS total_sales_value,
    COUNT(DISTINCT sh.ws_order_number) AS order_count,
    AVG(sh.ws_sales_price) AS avg_sales_price,
    STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') AS customers
FROM sales_hierarchy sh
LEFT JOIN web_page wp ON sh.ws_item_sk = wp.wp_web_page_sk
FULL OUTER JOIN catalog_page cps ON sh.ws_item_sk = cps.cp_catalog_page_sk
JOIN customer c ON sh.ws_order_number = c.c_customer_sk
WHERE sh.rn <= 10
AND (sh.ws_quantity IS NOT NULL OR sh.cs_quantity IS NOT NULL)
GROUP BY page_id
HAVING SUM(sh.ws_quantity + sh.cs_quantity) > 100
ORDER BY total_sales_value DESC
LIMIT 5;
