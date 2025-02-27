
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        RankedSales.total_quantity,
        RankedSales.total_profit,
        RankedSales.ws_item_sk
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.profit_rank <= 5
)
SELECT
    ta.i_item_id,
    ta.i_item_desc,
    COALESCE(ta.total_quantity, 0) AS quantity_sold,
    COALESCE(ta.total_profit, 0) AS total_profit,
    CASE 
        WHEN ta.total_profit > 1000 THEN 'High Profit'
        WHEN ta.total_profit > 500 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales 
     WHERE ws_item_sk = ta.ws_item_sk) AS order_count
FROM 
    TopSales ta
LEFT OUTER JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT DISTINCT ws_ship_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = ta.ws_item_sk
    )
WHERE 
    c.c_current_cdemo_sk IS NULL 
    OR c.c_current_hdemo_sk IS NULL
ORDER BY 
    ta.total_profit DESC;
