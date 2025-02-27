
WITH RankedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.catalog_page_sk) AS unique_catalog_pages,
        DENSE_RANK() OVER (PARTITION BY cr.returning_customer_sk ORDER BY SUM(cr.return_amount) DESC) AS return_rank
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        IFNULL(cd.cd_dep_count, 0) AS dependent_count,
        CASE 
            WHEN cd.cd_purchase_estimate > 500 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.dependent_count,
        cd.customer_value,
        COALESCE(ts.total_profit, 0) AS total_profit,
        rr.total_return_amount
    FROM 
        CustomerData cd
    LEFT JOIN 
        TotalSales ts ON cd.c_customer_id = ts.customer_sk
    LEFT JOIN 
        RankedReturns rr ON cd.c_customer_id = rr.returning_customer_sk AND rr.return_rank = 1
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.customer_value,
    cd.dependent_count,
    cd.total_profit,
    COALESCE(cd.total_return_amount, 0) AS largest_return,
    CASE 
        WHEN cd.total_profit > 1000 AND cd.total_return_amount > 500 THEN 'High Risk'
        WHEN cd.total_profit < 100 AND cd.total_return_amount = 0 THEN 'Low Risk'
        ELSE 'Moderate Risk'
    END AS risk_level
FROM 
    CombinedData cd
WHERE 
    (cd.cd_gender = 'F' OR cd.customer_value = 'High Value')
    AND (cd.total_profit > 0 OR cd.total_return_amount IS NOT NULL)
ORDER BY 
    cd.total_profit DESC, cd.total_return_amount DESC;
