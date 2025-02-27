
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
    UNION ALL
    SELECT 
        sh.ss_store_sk,
        sh.ss_item_sk,
        sh.total_sales + COALESCE(prev.total_sales, 0) AS total_sales,
        level + 1
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        SalesHierarchy prev ON sh.ss_item_sk = prev.ss_item_sk AND sh.level = prev.level + 1
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_ext_sales_price) AS total_revenue,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(NULLIF(ss.ss_ext_sales_price, 0)) AS avg_order_value,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ss.ss_ext_sales_price) DESC) as sales_rank,
    COALESCE(MAX(ss.ss_ext_discount_amt), 0) AS max_discount,
    STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_item_id, ')'), ', ') WITHIN GROUP (ORDER BY i.i_item_desc) AS sold_items
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    SalesHierarchy sh ON ss.ss_item_sk = sh.ss_item_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND (c.c_salutation IS NULL OR c.c_salutation <> 'Mr.')
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ss.ss_ext_sales_price) > 1000
ORDER BY 
    total_revenue DESC
LIMIT 10;
