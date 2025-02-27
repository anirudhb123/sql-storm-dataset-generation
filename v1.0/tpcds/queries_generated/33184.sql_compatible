
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    UNION ALL
    SELECT 
        cs_order_number,
        cs_sold_date_sk,
        cs_quantity,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_sold_date_sk)
    FROM 
        catalog_sales
)
SELECT 
    d.d_date AS SaleDate,
    SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) AS TotalProfit,
    COUNT(DISTINCT ss.ss_ticket_number) AS TotalSales,
    SUM(CASE 
            WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_quantity
            ELSE ws.ws_quantity
        END) AS TotalQuantitySold,
    (SELECT COUNT(DISTINCT sr_ticket_number) 
     FROM store_returns 
     WHERE sr_returned_date_sk = d.d_date_sk) AS TotalReturns,
    CASE 
        WHEN SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) > 10000 THEN 'High Profit'
        WHEN SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS ProfitCategory
FROM 
    date_dim d
LEFT JOIN 
    (SELECT ws_order_number, 
            SUM(ws_net_profit) AS ws_net_profit, 
            SUM(ws_quantity) AS ws_quantity 
     FROM 
        web_sales 
     GROUP BY 
        ws_order_number) ws ON ws.ws_order_number = SalesCTE.ws_order_number
LEFT JOIN 
    (SELECT cs_order_number, 
            SUM(cs_net_profit) AS cs_net_profit, 
            SUM(cs_quantity) AS cs_quantity 
     FROM 
        catalog_sales 
     GROUP BY 
        cs_order_number) cs ON cs.cs_order_number = SalesCTE.ws_order_number
LEFT JOIN 
    store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY 
    d.d_date
HAVING 
    SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) IS NOT NULL
ORDER BY 
    SaleDate DESC;
