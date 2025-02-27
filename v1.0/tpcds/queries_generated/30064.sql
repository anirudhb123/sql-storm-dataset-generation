
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesStatistics AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
    ORDER BY total_profit DESC
    LIMIT 5
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    cust.c_first_name,
    cust.c_last_name,
    COALESCE(ts.total_profit, 0) AS store_profit,
    sa.total_quantity,
    sa.total_sales,
    sa.avg_net_profit,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY sa.total_sales DESC) AS sales_rank
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN SalesStatistics sa ON sa.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
LEFT JOIN TopStores ts ON ts.s_store_sk = c.c_current_hdemo_sk
WHERE ca.ca_state IS NOT NULL 
  AND (c.c_birth_year BETWEEN 1980 AND 1990 OR c.c_first_shipto_date_sk IS NULL)
ORDER BY ca.ca_city, store_profit DESC;
