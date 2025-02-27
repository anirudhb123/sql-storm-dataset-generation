
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),

MaxReturns AS (
    SELECT 
        rr.returning_customer_sk,
        rr.return_count,
        rr.total_return_amt,
        ca.city AS customer_city,
        ca.state AS customer_state,
        cd.gender AS customer_gender,
        cd.marital_status AS customer_marital_status,
        DENSE_RANK() OVER (ORDER BY rr.total_return_amt DESC) AS rank_return_amt,
        CASE 
            WHEN cd_dep_count IS NULL THEN 'No Dependents' 
            WHEN cd_dep_count > 0 THEN 'Has Dependents' 
            ELSE 'No Dependents' 
        END AS dependent_status
    FROM 
        RankedReturns rr
    JOIN 
        customer ca ON rr.returning_customer_sk = ca.c_customer_sk
    JOIN 
        customer_demographics cd ON ca.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rr.return_count > 5
),

HighReturnDetails AS (
    SELECT 
        mr.returning_customer_sk,
        mr.return_count,
        mr.total_return_amt,
        mr.customer_city,
        mr.customer_state,
        mr.customer_gender,
        mr.customer_marital_status,
        mr.dependent_status,
        COUNT(DISTINCT ws.order_number) AS associated_web_sales,
        COALESCE(ROUND(AVG(ws.net_profit), 2), 0) AS avg_net_profit
    FROM 
        MaxReturns mr
    LEFT JOIN 
        web_sales ws ON mr.returning_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        mr.returning_customer_sk, 
        mr.return_count, 
        mr.total_return_amt, 
        mr.customer_city, 
        mr.customer_state, 
        mr.customer_gender, 
        mr.customer_marital_status,
        mr.dependent_status
)

SELECT 
    hrd.returning_customer_sk,
    hrd.return_count,
    hrd.total_return_amt,
    hrd.customer_city,
    hrd.customer_state,
    hrd.customer_gender,
    hrd.customer_marital_status,
    hrd.dependent_status,
    hrd.associated_web_sales,
    hrd.avg_net_profit
FROM 
    HighReturnDetails hrd
WHERE 
    (hrd.avg_net_profit > 1000 OR hrd.avg_net_profit IS NULL)
    AND hrd.dependent_status = 'Has Dependents'
ORDER BY 
    hrd.total_return_amt DESC
LIMIT 10;
