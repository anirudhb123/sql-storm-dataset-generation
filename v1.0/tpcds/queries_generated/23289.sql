
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS RankProfit,
        COALESCE(SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 0) AS RollingNetPaid,
        COUNT(DISTINCT CASE WHEN wd.d_dow IN (1, 2, 3, 4, 5) THEN ws.ws_order_number END) AS WeekdaySalesCount,
        MAX(CASE WHEN ws.ws_ship_date_sk IS NULL THEN 'Pending' ELSE 'Shipped' END) AS ShippingStatus
    FROM 
        web_sales ws
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    LEFT JOIN
        store s ON s.s_store_sk = (SELECT TOP 1 sr_store_sk 
                                   FROM store_returns 
                                   WHERE sr_item_sk = ws.ws_item_sk 
                                   ORDER BY sr_return_quantity DESC)
    WHERE 
        wd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_quantity, ws.ws_net_profit
), 
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.RankProfit,
        STRING_AGG(CONCAT('Item: ', CAST(rs.ws_item_sk AS varchar), ' - ', CAST(rs.ws_quantity AS varchar)), '; ') WITHIN GROUP (ORDER BY rs.RankProfit) AS Items
    FROM 
        RankedSales rs
    WHERE 
        rs.RankProfit <= 5
    GROUP BY 
        rs.ws_item_sk, rs.ws_quantity, rs.RankProfit
)
SELECT 
    tsi.Items,
    ts.RankingEstimate,
    ts.RollingNetPaid,
    CASE WHEN tsi.ws_quantity IS NULL THEN 'No Sales' ELSE 'Sales Available' END AS SalesStatus
FROM 
    (SELECT 
         ws.ws_item_sk AS Item,
         SUM(ws.ws_net_profit) AS RankingEstimate,
         COUNT(ws.ws_order_number) AS TotalSales
     FROM 
         web_sales ws
     WHERE 
         ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
     GROUP BY 
         ws.ws_item_sk
    ) ts
JOIN 
    TopSellingItems tsi ON ts.Item = tsi.ws_item_sk
WHERE 
    (ts.RankingEstimate > 0 OR ts.TotalSales IS NULL)
ORDER BY 
    tsi.RankingEstimate DESC, ts.TotalSales DESC;
