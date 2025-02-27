
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT ws.ws_ship_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_net_paid, d.d_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
),
AggregatedSales AS (
    SELECT d_year, ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_revenue
    FROM SalesData
    GROUP BY d_year, ws_item_sk
),
ItemMetrics AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        COALESCE(a.total_quantity, 0) AS total_quantity,
        COALESCE(a.total_revenue, 0) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY COALESCE(a.total_revenue, 0) DESC) AS rank
    FROM item i
    LEFT JOIN AggregatedSales a ON i.i_item_sk = a.ws_item_sk
)
SELECT 
    ch.c_first_name, 
    ch.c_last_name, 
    i.i_item_id, 
    i.i_item_desc,
    im.total_quantity,
    im.total_revenue
FROM CustomerHierarchy ch
JOIN ItemMetrics im ON im.rank <= 5
JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
WHERE c.c_current_addr_sk IS NOT NULL 
    AND im.total_revenue > 1000 
    AND im.total_quantity > 50
ORDER BY ch.c_last_name, ch.c_first_name, im.total_revenue DESC;
