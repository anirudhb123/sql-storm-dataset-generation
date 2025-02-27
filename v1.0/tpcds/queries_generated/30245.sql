
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)  -- Last 30 days
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk,
        SUM(total_quantity) AS total_quantity,
        SUM(total_profit) AS total_profit
    FROM 
        SalesCTE
    WHERE 
        rank <= 10
    GROUP BY 
        ws_item_sk
),
SalesSummary AS (
    SELECT 
        i_item_id, 
        COALESCE(t.total_quantity, 0) AS total_quantity,
        COALESCE(t.total_profit, 0) AS total_profit,
        i_brand,
        i_category
    FROM 
        item
    LEFT JOIN 
        TopSales t ON item.i_item_sk = t.ws_item_sk
)
SELECT 
    ss.brand,
    ss.category,
    SUM(ss.total_quantity) AS overall_quantity,
    SUM(ss.total_profit) AS overall_profit,
    CASE 
        WHEN SUM(ss.total_profit) IS NULL THEN 'No Profit'
        ELSE 'Profit Achieved'
    END AS profit_status,
    DENSE_RANK() OVER (ORDER BY SUM(ss.total_profit) DESC) AS profit_rank
FROM 
    (SELECT 
        i.brand AS brand,
        i.category AS category,
        COALESCE(ts.total_quantity, 0) AS total_quantity,
        COALESCE(ts.total_profit, 0) AS total_profit
     FROM 
        item i
     LEFT JOIN 
        TopSales ts ON i.i_item_sk = ts.ws_item_sk) ss
GROUP BY 
    ss.brand, ss.category
HAVING 
    SUM(ss.total_quantity) > 1000
ORDER BY 
    overall_profit DESC;
