
WITH SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
    UNION ALL
    SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity, SUM(cs_net_paid) AS total_sales
    FROM catalog_sales
    WHERE cs_item_sk IN (SELECT ws_item_sk FROM SalesCTE)
    GROUP BY cs_item_sk
),
ItemDetails AS (
    SELECT i.i_item_sk, i.i_item_desc, i.i_current_price,
           COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity,
           COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity,
           COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
           COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_current_price
)
SELECT ia.i_item_sk, ia.i_item_desc, ia.i_current_price,
       COALESCE(ia.total_store_quantity + ia.total_web_quantity, 0) AS total_quantity_sold,
       COALESCE(ia.total_store_sales + ia.total_web_sales, 0) AS total_revenue,
       CASE 
           WHEN (COALESCE(ia.total_store_sales + ia.total_web_sales, 0) > 0) 
           THEN ROUND((ia.total_store_sales + ia.total_web_sales) / NULLIF(total_quantity_sold, 0), 2)
           ELSE 0
       END AS average_price_per_unit,
       (SELECT COUNT(DISTINCT ca_state) FROM customer_address WHERE ca_address_sk IS NOT NULL) AS unique_states
FROM ItemDetails ia
WHERE ia.total_store_sales > 0 OR ia.total_web_sales > 0
ORDER BY total_revenue DESC
LIMIT 10;
