
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_cdemo_sk, 
        0 AS hierarchy_level 
    FROM customer 
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk, 
        ch.hierarchy_level + 1 
    FROM customer c 
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
StoreSales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS store_quantity,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ss.ss_item_sk
)
SELECT 
    ca.ca_state, 
    SUM(cs.total_quantity) AS total_web_sales_quantity,
    SUM(ss.store_quantity) AS total_store_sales_quantity,
    AVG(ss.avg_net_paid) AS average_store_net_paid,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers
FROM CustomerHierarchy ch
LEFT JOIN SalesData cs ON cs.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
LEFT JOIN StoreSales ss ON ss.ss_item_sk = cs.ws_item_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = ch.c_current_cdemo_sk
WHERE ca.ca_country = 'USA'
GROUP BY ca.ca_state
HAVING SUM(cs.total_net_profit) > 10000
ORDER BY total_web_sales_quantity DESC;
