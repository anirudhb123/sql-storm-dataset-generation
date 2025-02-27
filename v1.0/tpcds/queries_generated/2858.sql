
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        item.i_item_id, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_order
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy IN (1, 2, 3)
        )
    GROUP BY 
        ws.web_site_sk, item.i_item_id
),
TopSites AS (
    SELECT 
        web_site_sk, 
        total_quantity_sold, 
        total_net_profit, 
        rank_order
    FROM 
        RankedSales
    WHERE 
        rank_order <= 5
)
SELECT 
    ws.web_site_id, 
    ws.web_name, 
    COALESCE(ts.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ts.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN ts.total_net_profit > 1000 THEN 'High Profit'
        WHEN ts.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    web_site ws
LEFT JOIN 
    TopSites ts ON ws.web_site_sk = ts.web_site_sk
ORDER BY 
    ws.web_site_id;

-- Perform a comparison of retail and catalog sales for the same items over the same period.
SELECT 
    item.i_item_id, 
    SUM(COALESCE(ws.ws_quantity, 0)) AS web_sales_quantity,
    SUM(COALESCE(cs.cs_quantity, 0)) AS catalog_sales_quantity,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS web_sales_net_profit, 
    SUM(COALESCE(cs.cs_net_profit, 0)) AS catalog_sales_net_profit
FROM 
    item
LEFT JOIN 
    web_sales ws ON item.i_item_sk = ws.ws_item_sk 
    AND ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy IN (1, 2, 3)
    )
LEFT JOIN 
    catalog_sales cs ON item.i_item_sk = cs.cs_item_sk 
    AND cs.cs_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy IN (1, 2, 3)
    )
GROUP BY 
    item.i_item_id
HAVING 
    SUM(COALESCE(ws.ws_net_profit, 0)) > 500 
    OR SUM(COALESCE(cs.cs_net_profit, 0)) > 500
ORDER BY 
    web_sales_net_profit DESC;
