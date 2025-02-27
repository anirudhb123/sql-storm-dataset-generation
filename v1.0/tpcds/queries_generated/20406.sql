
WITH RankedSales AS (
    SELECT 
        ss.sold_date_sk,
        ss.store_sk,
        ss.item_sk,
        ss.quantity,
        ss.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY ss.net_profit DESC) AS rn
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.item_sk = i.item_sk
    WHERE 
        ss.sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss.sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category_id = i.i_category_id)
),
CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.store_sk
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
TotalReturns AS (
    SELECT 
        cr.store_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.return_amt) AS total_return_amt
    FROM 
        CustomerReturns cr
    GROUP BY 
        cr.store_sk
),
SalesAnalysis AS (
    SELECT 
        rs.store_sk,
        SUM(rs.net_profit) AS total_net_profit,
        COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(tr.total_return_quantity, 0) > 0 
                THEN (SUM(rs.net_profit) / NULLIF(COALESCE(tr.total_return_quantity, 0), 0))
            ELSE 
                SUM(rs.net_profit)
        END AS adjusted_profit
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.store_sk = tr.store_sk
    GROUP BY 
        rs.store_sk
)
SELECT 
    sa.store_sk,
    sa.total_net_profit,
    sa.total_return_quantity,
    sa.total_return_amt,
    sa.adjusted_profit,
    CASE 
        WHEN sa.adjusted_profit IS NOT NULL THEN 'Valid'
        ELSE 'Invalid'
    END AS profitability_status
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.adjusted_profit DESC
LIMIT 50;
