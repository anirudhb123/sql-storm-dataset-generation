
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_category_id, i_category, i_class_id
    FROM item
    WHERE i_category_id IS NOT NULL
    UNION ALL
    SELECT i.category_id, i.category, i.class_id
    FROM item i
    JOIN CategoryHierarchy ch ON i.class_id = ch.i_class_id
)
SELECT 
    cd.cd_demo_sk AS demo_key,
    cd.cd_gender AS gender,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_net_profit) AS average_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    MAX(ws.ws_sales_price) AS max_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price
FROM 
    customer_demographics cd
LEFT JOIN 
    customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    CategoryHierarchy ch ON ws.ws_item_sk = ch.i_category_id
WHERE 
    cd.cd_gender IS NOT NULL
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    )
GROUP BY 
    cd.cd_demo_sk, cd.cd_gender
HAVING 
    total_quantity > 100
ORDER BY 
    average_net_profit DESC
LIMIT 10;
