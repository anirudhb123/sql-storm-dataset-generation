
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(sr_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
), HighReturnCustomers AS (
    SELECT 
        r.returning_customer_sk,
        r.total_returned,
        r.return_count,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS credit_rating
    FROM 
        RankedReturns r
    JOIN 
        customer_demographics cd ON r.returning_customer_sk = cd.cd_demo_sk
    WHERE 
        r.return_count > 5 AND rnk <= 100
), ReturnReasons AS (
    SELECT 
        sr_reason_sk,
        COUNT(DISTINCT sr_ticket_number) AS reason_count
    FROM 
        store_returns sr
    GROUP BY 
        sr_reason_sk
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > 10
), FinalBenchmark AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name,
        c.c_last_name,
        hrc.total_returned,
        hrc.return_count,
        rr.reason_sk,
        rr.reason_count,
        COALESCE(ROW_NUMBER() OVER (PARTITION BY hrc.return_count ORDER BY hrc.total_returned DESC), 0) AS rank_in_returns
    FROM 
        customer c
    LEFT JOIN 
        HighReturnCustomers hrc ON c.c_customer_sk = hrc.returning_customer_sk
    LEFT JOIN 
        ReturnReasons rr ON rr.reason_sk = (SELECT TOP 1 sr_reason_sk FROM store_returns sr WHERE sr.returning_customer_sk = hrc.returning_customer_sk ORDER BY sr.return_quantity DESC)
)
SELECT 
    *,
    CASE 
        WHEN reason_count IS NULL THEN 'No return reason available'
        ELSE 'Available return reason'
    END AS reason_availability
FROM 
    FinalBenchmark
WHERE 
    total_returned IS NOT NULL
ORDER BY 
    total_returned DESC, c_customer_id;
