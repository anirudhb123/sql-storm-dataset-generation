
WITH RECURSIVE sales_data AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM catalog_sales
    GROUP BY cs_item_sk
),
high_profit_items AS (
    SELECT
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_net_profit
    FROM sales_data sd
    WHERE sd.rank <= 10
),
item_details AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(MAX(i.i_current_price), 0) AS max_price,
        COUNT(DISTINCT ws.ws_order_number) AS sales_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT
    hi.cs_item_sk,
    id.i_item_id,
    id.i_item_desc,
    hi.total_quantity,
    hi.total_net_profit,
    id.max_price,
    id.sales_count
FROM high_profit_items hi
JOIN item_details id ON hi.cs_item_sk = id.i_item_id
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk IN (
    SELECT DISTINCT c_current_cdemo_sk
    FROM customer
    WHERE c_birth_year IS NOT NULL 
      AND (c_birth_month IS NULL OR c_birth_month > 6)
)
ORDER BY hi.total_net_profit DESC, hi.total_quantity DESC;

-- Genealogy of sales data, including oddities
SELECT ws.ws_item_sk,
       ws.ws_sold_date_sk,
       SUM(ws.ws_quantity) AS total_quantity,
       COUNT(DISTINCT ws.ws_order_number) AS order_count,
       CASE
           WHEN SUM(ws.ws_net_profit) IS NULL THEN 0
           ELSE SUM(ws.ws_net_profit)
       END AS net_profit
FROM web_sales ws
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_item_sk = ws.ws_item_sk
          HAVING SUM(ss.ss_quantity) > 100
          )
GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
HAVING ROUND(SUM(ws.ws_net_profit), 2) BETWEEN 500 AND (
          SELECT MAX(ws2.ws_net_profit)
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = ws.ws_item_sk
          AND ws2.ws_sold_date_sk < CURRENT_DATE
      )
ORDER BY net_profit DESC, total_quantity ASC
LIMIT 5;
