
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS hierarchy_level
    FROM customer 
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
, SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    WHERE d.d_year >= 2020
    GROUP BY ws.ws_item_sk
)
SELECT
    ca.ca_state,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    AVG(sd.total_net_paid) AS average_net_sales,
    MAX(sd.total_sales) AS max_sales_item,
    CASE
        WHEN AVG(sd.total_net_paid) IS NULL THEN 'No Sales Data'
        ELSE 'Sales Data Available'
    END AS sales_data_status
FROM customer_address ca
LEFT JOIN CustomerHierarchy ch ON ch.c_current_cdemo_sk = ca.ca_address_sk
LEFT JOIN SalesData sd ON sd.ws_item_sk IN (
    SELECT i.i_item_sk 
    FROM item i 
    WHERE i.i_current_price > 50
)
GROUP BY ca.ca_state
ORDER BY COUNT(DISTINCT ch.c_customer_sk) DESC
LIMIT 10;
