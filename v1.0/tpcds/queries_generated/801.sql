
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000000 AND 1001000
    GROUP BY ws_sold_date_sk, ws_item_sk
),
PopularItems AS (
    SELECT 
        ws_item_sk,
        DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM SalesData
    WHERE total_quantity > 100
),
ItemDetails AS (
    SELECT 
        i_item_id,
        i_item_desc,
        i_current_price,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN i_current_price < ib_lower_bound THEN 'Low'
            WHEN i_current_price BETWEEN ib_lower_bound AND ib_upper_bound THEN 'Medium'
            ELSE 'High'
        END AS price_band
    FROM item
    JOIN income_band ON (i_current_price BETWEEN ib_lower_bound AND ib_upper_bound)
)
SELECT 
    pd.rank,
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    sd.total_quantity,
    sd.total_net_profit,
    id.price_band
FROM PopularItems pd
JOIN SalesData sd ON pd.ws_item_sk = sd.ws_item_sk
JOIN ItemDetails id ON pd.ws_item_sk = id.i_item_sk
ORDER BY pd.rank, sd.total_net_profit DESC;
