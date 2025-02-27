
WITH RECURSIVE CustomerWithReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id
    FROM 
        CustomerWithReturns c
    WHERE 
        c.return_count IS NOT NULL 
        AND c.return_count > 0 
        AND EXISTS (
            SELECT 1 
            FROM customer_demographics cd 
            WHERE cd.cd_demo_sk = c.c_customer_sk 
            AND cd.cd_gender = 'F'
        )
),
TopCustomers AS (
    SELECT 
        fc.c_customer_id,
        SUM(sr.sr_return_amt) AS total_returned
    FROM 
        FilteredCustomers fc
    JOIN 
        store_returns sr ON fc.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        fc.c_customer_id
    ORDER BY 
        total_returned DESC
    LIMIT 10
),
ReturnStatistics AS (
    SELECT 
        COUNT(*) AS total_returns,
        AVG(total_returned) AS avg_returned
    FROM 
        TopCustomers
)
SELECT 
    ts.c_customer_id,
    ts.total_returned,
    rt.total_returns,
    rt.avg_returned,
    CONCAT('Customer ', ts.c_customer_id, ' has returned $', FORMAT(ts.total_returned, 2), ' worth of items.') AS customer_return_message
FROM 
    TopCustomers ts
CROSS JOIN 
    ReturnStatistics rt
WHERE 
    rt.total_returns > 0 
    AND ts.total_returned > rt.avg_returned
ORDER BY 
    ts.total_returned DESC;
