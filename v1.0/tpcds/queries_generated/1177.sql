
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS PriceRank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND ws.ws_net_profit > 0
),
HighProfitSales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_ext_sales_price,
        sd.ws_ext_ship_cost,
        sd.ws_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.ProfitRank <= 10
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(CAST(NULLIF(i.i_current_price, 0) AS DECIMAL(10, 2)), 'N/A') AS current_price,
        COALESCE(CAST(NULLIF(i.i_wholesale_cost, 0) AS DECIMAL(10, 2)), 'N/A') AS wholesale_cost
    FROM 
        item i
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    SUM(hps.ws_quantity) AS total_quantity,
    SUM(hps.ws_ext_sales_price) AS total_sales,
    AVG(hps.ws_net_profit) AS average_profit,
    MAX(hps.ws_net_profit) AS max_profit,
    MIN(hps.ws_net_profit) AS min_profit,
    CONCAT('Total Sold: ', SUM(hps.ws_quantity), ', Total Sales: $', ROUND(SUM(hps.ws_ext_sales_price), 2)) AS sales_summary
FROM 
    HighProfitSales hps
JOIN 
    ItemDetails id ON hps.ws_item_sk = id.i_item_sk
GROUP BY 
    id.i_item_id, id.i_product_name
ORDER BY 
    total_sales DESC
LIMIT 20
UNION ALL
SELECT 
    'N/A' AS i_item_id,
    'Miscellaneous' AS i_product_name,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit,
    MAX(ws.ws_net_profit) AS max_profit,
    MIN(ws.ws_net_profit) AS min_profit,
    CONCAT('Total Sold: ', SUM(ws.ws_quantity), ', Total Sales: $', ROUND(SUM(ws.ws_ext_sales_price), 2)) AS sales_summary
FROM 
    web_sales ws
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
    AND ws.ws_net_profit IS NULL;
