
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Unknown' 
            ELSE 'Price Available' 
        END AS price_status
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL OR i.i_current_price IS NULL
),
SalesAnalysis AS (
    SELECT 
        R.ws_item_sk,
        SD.i_item_id,
        SD.i_item_desc,
        SD.price_status,
        R.total_sales_quantity,
        R.total_net_profit,
        (R.total_net_profit / NULLIF(R.total_sales_quantity, 0)) AS profit_per_unit,
        COALESCE(NULLIF(R.total_sales_quantity, 0), 1) * 100 AS sales_factor
    FROM 
        RankedSales R
    JOIN 
        ItemDetails SD ON R.ws_item_sk = SD.i_item_id
    WHERE 
        R.sales_rank = 1
)
SELECT 
    SA.i_item_id,
    SA.i_item_desc,
    SA.total_sales_quantity,
    SA.total_net_profit,
    SA.profit_per_unit,
    SA.sales_factor,
    CASE 
        WHEN SA.profit_per_unit < 10 THEN 'Low Profit'
        WHEN SA.profit_per_unit BETWEEN 10 AND 50 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    SalesAnalysis SA
WHERE 
    (SA.total_net_profit > 0 OR SA.total_sales_quantity IS NULL)
    AND (SA.sales_factor > 50 OR SA.total_sales_quantity = 0)
ORDER BY 
    SA.total_net_profit DESC, 
    SA.i_item_desc COLLATE 'C' ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
