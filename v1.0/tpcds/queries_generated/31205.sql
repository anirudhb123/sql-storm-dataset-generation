
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_quantity,
        ss_net_profit,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)

    UNION ALL

    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_net_profit,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_item_sk = sh.ss_item_sk
    WHERE 
        sh.level < 5
)

SELECT 
    ca.ca_country AS country,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(sh.ss_net_profit) AS total_net_profit,
    AVG(sh.ss_quantity) AS avg_quantity_sold,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS product_names,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    sales_hierarchy sh ON sh.ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_city = ca.ca_city)
JOIN 
    item i ON sh.ss_item_sk = i.i_item_sk
JOIN 
    web_sales ws ON ws.ws_item_sk = sh.ss_item_sk
LEFT JOIN 
    promotion p ON p.p_item_sk = sh.ss_item_sk AND p.p_discount_active = 'Y'
WHERE 
    c.c_birth_year > 1980
    AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_country
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 50
ORDER BY 
    total_net_profit DESC
LIMIT 10;
