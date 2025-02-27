
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
AggregateSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity_sold,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd 
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(ib.ib_income_band_sk, 0) AS income_band_sk
    FROM 
        item i
    LEFT JOIN 
        household_demographics hd ON i.i_brand_id = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    id.i_brand,
    COALESCE(as.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(as.total_net_profit, 0) AS total_net_profit,
    id.income_band_sk
FROM 
    ItemDetails id
LEFT JOIN 
    AggregateSales as ON id.i_item_sk = as.ws_item_sk
WHERE 
    id.i_current_price > (SELECT AVG(i_current_price) FROM item) 
    AND id.i_item_id IS NOT NULL
ORDER BY 
    total_net_profit DESC
LIMIT 100;
