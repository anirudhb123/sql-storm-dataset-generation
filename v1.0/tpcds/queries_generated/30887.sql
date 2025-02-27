
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_category_id, i_category, i_class_id, i_class, i_item_id, i_product_name
    FROM item
    WHERE i_class_id IS NOT NULL
    UNION ALL
    SELECT p.i_category_id, p.i_category, p.i_class_id, p.i_class, p.i_item_id, p.i_product_name
    FROM item p
    JOIN CategoryHierarchy c ON p.i_class_id = c.i_class_id
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN CategoryHierarchy ch ON ws.ws_item_sk = ch.i_item_sk
    GROUP BY ws.ws_item_sk
),
SalesByStore AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN CategoryHierarchy ch ON ss.ss_item_sk = ch.i_item_sk
    GROUP BY ss.ss_store_sk
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    SUM(sd.total_quantity) AS total_quantity,
    SUM(sd.total_profit) AS total_profit,
    sb.store_department,
    RANK() OVER (PARTITION BY sb.store_department ORDER BY SUM(sd.total_profit) DESC) AS department_profit_rank
FROM 
    customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
    LEFT JOIN (
        SELECT ss.ss_store_sk, 
               CASE 
                   WHEN ss.ss_net_profit < 100 THEN 'Low Profit'
                   WHEN ss.ss_net_profit BETWEEN 100 AND 500 THEN 'Moderate Profit'
                   ELSE 'High Profit'
               END AS store_department
        FROM store_sales ss
    ) sb ON c.c_customer_sk = sb.ss_store_sk
GROUP BY 
    ca.ca_address_id, 
    ca.ca_city, 
    sb.store_department
HAVING 
    SUM(sd.total_profit) > 1000
ORDER BY 
    total_profit DESC NULLS LAST;
