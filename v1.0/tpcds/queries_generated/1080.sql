
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_ship_mode_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(i.i_brand, 'Unknown') AS brand_name
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date > CURRENT_DATE OR i.i_rec_end_date IS NULL)
),
ShippingModes AS (
    SELECT 
        sm_ship_mode_sk,
        sm_type
    FROM 
        ship_mode
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.brand_name,
    sd.ws_ship_mode_sk,
    sm.sm_type,
    sd.total_quantity,
    sd.total_net_profit
FROM 
    SalesData sd
JOIN 
    ItemDetails id ON sd.ws_item_sk = id.i_item_sk
LEFT JOIN 
    ShippingModes sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    sd.item_rank = 1
ORDER BY 
    sd.total_net_profit DESC;
