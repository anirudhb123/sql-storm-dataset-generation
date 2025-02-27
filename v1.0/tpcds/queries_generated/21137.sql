
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS ProfitRank,
        (SELECT SUM(ws_sales_price) 
         FROM web_sales 
         WHERE ws_ship_date_sk = ws_sold_date_sk AND ws_item_sk = ws.item_sk) AS TotalSales
    FROM 
        web_sales ws
),

FilteredReturns AS (
    SELECT 
        sr.returned_date,
        sr.return_time,
        sr.item_sk,
        SUM(sr.return_quantity) AS TotalReturned,
        COUNT(DISTINCT sr.returning_customer_sk) AS UniqueReturners
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date IN (SELECT d_date FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr.returned_date, sr.return_time, sr.item_sk
),

ProfitableItems AS (
    SELECT 
        ir.item_sk,
        ir.sales_profit,
        ir.sales_count,
        ROW_NUMBER() OVER (ORDER BY ir.sales_profit DESC) AS ItemRank
    FROM (
        SELECT 
            cs.cs_item_sk,
            SUM(cs.cs_net_profit) AS sales_profit,
            COUNT(*) AS sales_count
        FROM 
            catalog_sales cs
        GROUP BY 
            cs.cs_item_sk
    ) ir
    WHERE
        ir.sales_profit > 5000
)

SELECT 
    ca.city,
    ca.state,
    SUM(pr.sales_profit) AS TotalProfit,
    AVG(f.TotalReturned) AS AvgReturns,
    STRING_AGG(DISTINCT i.item_id, ', ') AS TopItemsReturned,
    COALESCE(MAX(RD.ws_net_profit), 0) AS MaxNetProfit
FROM 
    customer_address ca
LEFT JOIN 
    FilteredReturns f ON f.item_sk = ca.ca_address_sk
JOIN 
    ProfitableItems pr ON pr.item_sk = f.item_sk
LEFT JOIN 
    RankedSales RD ON RD.ws_order_number = pr.item_rank
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT ca.ca_address_sk) > 3
ORDER BY 
    TotalProfit DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
