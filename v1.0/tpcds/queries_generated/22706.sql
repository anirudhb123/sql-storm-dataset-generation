
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr.item_sk ORDER BY sr.return_quantity DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
        AND sr.returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.item_sk) AS unique_returns,
        SUM(sr.return_quantity) AS total_return_quantity,
        AVG(sr.return_quantity) AS avg_return_quantity,
        COUNT(sr.customer_sk) OVER (PARTITION BY c.c_customer_sk) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopReturns AS (
    SELECT 
        r.returned_date_sk,
        r.item_sk,
        r.return_quantity,
        r.rn
    FROM 
        RankedReturns r
    WHERE 
        r.rn <= 5
)
SELECT 
    cs.c_customer_sk,
    cs.unique_returns,
    cs.total_return_quantity,
    cs.avg_return_quantity,
    COALESCE(tr.return_quantity, 0) AS top_return_quantity
FROM 
    CustomerStats cs
LEFT JOIN 
    TopReturns tr ON cs.unique_returns > 0
WHERE 
    cs.total_purchases > 5
    AND cs.avg_return_quantity < (
        SELECT 
            AVG(total_return_quantity) 
        FROM 
            CustomerStats
        WHERE 
            total_purchases > 1
    ) 
ORDER BY 
    cs.total_return_quantity DESC;

