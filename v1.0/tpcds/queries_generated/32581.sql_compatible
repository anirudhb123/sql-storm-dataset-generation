
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ship_mode_sk, 
        SUM(ws.net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ship_mode_sk ORDER BY SUM(ws.net_paid) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ship_mode_sk
),
CustomerReturns AS (
    SELECT 
        sr.customer_sk, 
        SUM(sr.return_amt) AS total_return_amt,
        COUNT(sr.return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.customer_sk
),
ShipModeDetails AS (
    SELECT 
        sm.ship_mode_sk,
        sm.sm_type,
        COALESCE(tc.total_sales, 0) AS total_sales,
        COALESCE(cr.total_return_amt, 0) AS total_returns,
        COALESCE(cr.total_returns, 0) AS return_count,
        (COALESCE(tc.total_sales, 0) - COALESCE(cr.total_return_amt, 0)) AS net_sales
    FROM 
        ship_mode sm
    LEFT JOIN 
        SalesCTE tc ON sm.ship_mode_sk = tc.ship_mode_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.customer_sk IN (SELECT DISTINCT ws.bill_customer_sk FROM web_sales ws WHERE ws.ship_mode_sk = sm.ship_mode_sk)
)
SELECT 
    smd.sm_type, 
    smd.total_sales, 
    smd.total_returns, 
    smd.return_count, 
    smd.net_sales,
    CASE 
        WHEN smd.return_count > 0 THEN (smd.total_returns / smd.return_count) * 100
        ELSE 0
    END AS return_percentage
FROM 
    ShipModeDetails smd
WHERE 
    smd.net_sales > 10000
ORDER BY 
    smd.net_sales DESC;
