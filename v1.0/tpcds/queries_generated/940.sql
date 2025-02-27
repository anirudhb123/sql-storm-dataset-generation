
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sold_date_sk DESC) AS OrderRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 100
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_net_profit) AS TotalProfit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
FilteredReturns AS (
    SELECT 
        sr.returned_date_sk,
        COUNT(*) AS ReturnCount,
        SUM(sr.return_amt) AS TotalReturnedAmount
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
    GROUP BY 
        sr.returned_date_sk
    HAVING 
        SUM(sr.return_amt) > 500
)
SELECT 
    r.r_reason_desc,
    cs.cd_gender,
    cs.TotalOrders,
    cs.TotalProfit,
    fr.ReturnCount,
    fr.TotalReturnedAmount
FROM 
    reason r
JOIN 
    FilteredReturns fr ON r.r_reason_sk = fr.returned_date_sk
JOIN 
    CustomerStats cs ON cs.TotalOrders > 5
WHERE 
    (cs.cd_gender = 'M' OR cs.cd_marital_status = 'S')
ORDER BY 
    cs.TotalProfit DESC
LIMIT 10;
