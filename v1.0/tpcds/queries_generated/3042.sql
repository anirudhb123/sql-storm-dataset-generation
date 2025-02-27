
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
), 
AggregatedSales AS (
    SELECT 
        item.i_item_id, 
        SUM(sd.ws_quantity) as total_quantity,
        SUM(sd.ws_net_profit) as total_profit
    FROM 
        SalesData sd
    JOIN 
        item item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        item.i_item_id
), 
TopItems AS (
    SELECT 
        i_item_id,
        total_quantity,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) as rank
    FROM 
        AggregatedSales
    WHERE 
        total_profit > 1000
)
SELECT 
    ti.i_item_id,
    ti.total_quantity,
    ti.total_profit,
    COALESCE(ROUND(ti.total_profit / NULLIF(SUM(ws_ext_sales_price) OVER (PARTITION BY sm_ship_mode_sk), 0), 2), 0) as profit_percentage,
    CASE 
        WHEN ti.total_quantity > 500 THEN 'High Volume'
        WHEN ti.total_quantity BETWEEN 250 AND 500 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END as volume_category
FROM 
    TopItems ti
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk IN (SELECT DISTINCT ws_ship_mode_sk FROM web_sales WHERE ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_id = ti.i_item_id))
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_profit DESC;
