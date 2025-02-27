
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
aggregate_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales_amount,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM (
        SELECT ws_item_sk, ws_quantity, ws_sales_price, ws_net_profit 
        FROM sales_data 
        WHERE rn = 1
    ) sd
    GROUP BY sd.ws_item_sk
)
SELECT 
    ia.i_item_id,
    COALESCE(as.total_quantity, 0) AS quantity_sold,
    COALESCE(as.total_sales_amount, 0) AS sales_amount,
    COALESCE(as.total_net_profit, 0) AS net_profit,
    i.i_current_price,
    CASE 
        WHEN COALESCE(as.total_quantity, 0) = 0 THEN NULL
        ELSE (COALESCE(as.total_sales_amount, 0) / COALESCE(as.total_quantity, 0))
    END AS average_sales_price
FROM item i
LEFT JOIN aggregate_sales as ON i.i_item_sk = as.ws_item_sk
WHERE i.i_current_price > 20.00
ORDER BY net_profit DESC
LIMIT 100;
