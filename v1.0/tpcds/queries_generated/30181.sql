
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT ws_sold_date_sk, ws_item_sk, total_quantity + ws_total.quantity, total_net_profit + ws_total.net_profit
    FROM SalesCTE AS total
    JOIN (
        SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) AS quantity, SUM(ws_net_profit) AS net_profit
        FROM web_sales
        WHERE ws_sold_date_sk < (SELECT MAX(d_date_sk) - 30 FROM date_dim)
        GROUP BY ws_sold_date_sk, ws_item_sk
    ) AS ws_total ON total.ws_item_sk = ws_total.ws_item_sk
)
SELECT
    item.i_item_id,
    item.i_item_desc,
    COALESCE(SUM(ss.net_profit), 0) AS store_net_profit,
    SUM(ws.total_net_profit) AS web_net_profit,
    (CASE WHEN SUM(ws.total_net_profit) > SUM(ss.net_profit)
            THEN 'Web Sales Perform Better'
          ELSE 'Store Sales Perform Better' END) AS performance_comparison,
    ROW_NUMBER() OVER (PARTITION BY item.i_item_id ORDER BY SUM(ws.total_net_profit) DESC) AS rank
FROM item
LEFT JOIN (SELECT ss_item_sk, SUM(ss_net_profit) AS net_profit FROM store_sales GROUP BY ss_item_sk) AS ss ON item.i_item_sk = ss.ss_item_sk
LEFT JOIN (SELECT ws_item_sk, SUM(ws_net_profit) AS total_net_profit FROM SalesCTE GROUP BY ws_item_sk) AS ws ON item.i_item_sk = ws.ws_item_sk
WHERE item.i_current_price IS NOT NULL
GROUP BY item.i_item_id, item.i_item_desc
HAVING (COALESCE(SUM(ss.net_profit), 0) + SUM(ws.total_net_profit)) > 1000
ORDER BY performance_comparison, store_net_profit DESC, web_net_profit DESC;
