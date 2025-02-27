
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 50
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
        CASE 
            WHEN i.i_current_price IS NULL THEN 0
            ELSE i.i_current_price * 1.1
        END AS adjusted_price
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
)
SELECT 
    sd.ws_sold_date_sk,
    id.i_item_desc,
    id.promotion_name,
    sd.total_quantity,
    sd.total_profit,
    id.adjusted_price,
    CASE
        WHEN sd.total_profit > 1000 THEN 'High Profit'
        WHEN sd.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM store s
            WHERE s.s_store_sk = (SELECT ss.ss_store_sk FROM store_sales ss WHERE ss.ss_item_sk = sd.ws_item_sk LIMIT 1)
            AND s.s_state = 'CA'
        ) THEN 'California Store'
        ELSE 'Non-California Store'
    END AS store_category
FROM SalesData sd
JOIN ItemDetails id ON sd.ws_item_sk = id.i_item_sk
WHERE sd.rank_profit <= 5
ORDER BY sd.total_profit DESC, sd.total_quantity DESC;
