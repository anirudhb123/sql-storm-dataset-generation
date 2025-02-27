
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws.quantity,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
SalesAggregate AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.net_paid_inc_tax) AS TotalRevenue,
        AVG(ws.net_profit) AS AverageProfit,
        COUNT(DISTINCT ws.order_number) AS TotalOrders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.return_quantity,
        COALESCE(SUM(cr.return_amt), 0) AS TotalReturnAmount,
        COUNT(cr.returning_customer_sk) AS ReturnCount
    FROM 
        catalog_returns cr
    LEFT JOIN 
        store s ON cr.returning_customer_sk = s.store_sk
    WHERE 
        s.city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = (SELECT MIN(c_current_addr_sk) FROM customer))
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    sa.web_site_sk,
    sa.TotalRevenue,
    sa.AverageProfit,
    cr.TotalReturnAmount,
    cr.ReturnCount
FROM 
    SalesAggregate sa
LEFT JOIN 
    CustomerReturns cr ON sa.web_site_sk = cr.returning_customer_sk
WHERE 
    sa.TotalRevenue > 1000
    AND (cr.TotalReturnAmount IS NULL OR cr.TotalReturnAmount < 100)
UNION ALL
SELECT 
    ws.web_site_sk,
    SUM(ws.net_paid) AS TotalRevenue,
    AVG(ws.net_profit) AS AverageProfit,
    NULL AS TotalReturnAmount,
    NULL AS ReturnCount
FROM 
    web_sales ws
JOIN 
    RankedSales rs ON ws.order_number = rs.order_number
WHERE 
    rs.ProfitRank <= 10
GROUP BY 
    ws.web_site_sk
ORDER BY 
    TotalRevenue DESC, AverageProfit DESC
FETCH FIRST 100 ROWS ONLY;
