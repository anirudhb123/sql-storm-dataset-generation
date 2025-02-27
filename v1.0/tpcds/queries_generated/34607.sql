
WITH RECURSIVE sales_data AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
    HAVING SUM(ws_net_profit) > 0

    UNION ALL

    SELECT cs_sold_date_sk, cs_item_sk, SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_sold_date_sk, cs_item_sk
    HAVING SUM(cs_net_profit) > 0
),
item_sales AS (
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, SUM(sd.total_profit) AS total_profit
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk OR i.i_item_sk = sd.cs_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
top_items AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY total_profit DESC) AS rank 
    FROM item_sales
)
SELECT ti.i_item_id, ti.i_product_name, ti.total_profit, 
       COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
       COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
       (CASE WHEN COUNT(ws.ws_order_number) > 0 THEN 'Web' ELSE 'Store' END) AS predominant_sales_channel
FROM top_items ti
LEFT JOIN web_sales ws ON ti.i_item_sk = ws.ws_item_sk 
LEFT JOIN store_sales ss ON ti.i_item_sk = ss.ss_item_sk 
WHERE ti.rank = 1
GROUP BY ti.i_item_id, ti.i_product_name, ti.total_profit
ORDER BY total_profit DESC
LIMIT 10
```
