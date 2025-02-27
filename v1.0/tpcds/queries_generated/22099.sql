
WITH RankedReturns AS (
    SELECT 
        sr.returning_customer_sk,
        sr.returning_cdemo_sk,
        sr.return_quantity,
        RANK() OVER (PARTITION BY sr.returning_customer_sk ORDER BY sr.returned_date_sk DESC) AS return_rank
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity IS NOT NULL
),
TopReturns AS (
    SELECT 
        r.returning_customer_sk,
        COUNT(*) AS total_returns 
    FROM 
        RankedReturns r
    WHERE 
        r.return_rank <= 5
    GROUP BY 
        r.returning_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        tb.total_returns,
        COALESCE(tb.total_returns, 0) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        TopReturns tb ON c.c_customer_sk = tb.returning_customer_sk
),
SalesComparison AS (
    SELECT 
        CASE 
            WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High Value'
            WHEN SUM(ws.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_count
    FROM 
        web_sales ws
    GROUP BY 
        sales_category
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    COALESCE(sc.customer_count, 0) AS high_value_customers,
    CASE 
        WHEN cd.return_count > 0 THEN 'Frequent Returner'
        ELSE 'Non-Frequent Returner'
    END AS returner_status
FROM 
    CustomerData cd
LEFT JOIN 
    SalesComparison sc ON cd.return_count > 2
WHERE 
    cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND (cd.cd_marital_status <> 'S' OR cd.cd_marital_status IS NULL)
ORDER BY 
    cd.cd_purchase_estimate DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
