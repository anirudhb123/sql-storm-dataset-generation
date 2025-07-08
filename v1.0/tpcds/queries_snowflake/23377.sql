
WITH SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
), 
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_sold_date_sk) AS selling_days
    FROM 
        SalesCTE
    WHERE 
        rn <= 5
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(a.total_quantity, 0) AS quantity_sold,
    COALESCE(a.total_profit, 0) AS total_profit,
    CASE 
        WHEN a.selling_days IS NULL OR a.selling_days = 0 
        THEN 'No sales data'
        ELSE CONCAT('Sold on ', 
            (SELECT LISTAGG(DISTINCT d.d_day_name, ', ') WITHIN GROUP (ORDER BY d.d_day_name) 
             FROM date_dim d 
             WHERE d.d_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_item_sk = i.i_item_sk)))
    END AS sales_info
FROM 
    item i
LEFT JOIN 
    AggregatedSales a ON i.i_item_sk = a.ws_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    a.total_profit DESC NULLS LAST,
    quantity_sold DESC,
    i.i_item_id
LIMIT 10;
