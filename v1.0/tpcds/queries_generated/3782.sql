
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amount) AS total_returned_amount
    FROM catalog_returns cr
    WHERE cr.returned_date_sk >= (
        SELECT MAX(d_date_sk)
        FROM date_dim 
        WHERE d_year = 2022
    )
    GROUP BY cr.returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        CEIL(cd.cd_purchase_estimate / 100) AS income_bracket
    FROM customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND cd.cd_gender IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_count,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amount) AS total_returned_amount
    FROM catalog_returns cr
    JOIN CustomerReturns c ON cr.returning_customer_sk = c.returning_customer_sk
    GROUP BY cr.returning_customer_sk
),
TotalReturns AS (
    SELECT 
        COALESCE(c.customer_sk, -1) AS customer_sk,
        COALESCE(ar.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(ar.total_returned_amount, 0.0) AS total_returned_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_bracket
    FROM customer c
    LEFT JOIN AggregatedReturns ar ON c.c_customer_sk = ar.returning_customer_sk
    LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    w.w_warehouse_name,
    SUM(CASE WHEN total_returned_amount > 0 THEN total_returned_amount ELSE NULL END) AS returned_amount,
    AVG(total_returned_quantity) AS avg_returned_quantity,
    COUNT(DISTINCT customer_sk) AS active_customers
FROM TotalReturns tr
JOIN inventory i ON tr.customer_sk = i.inv_item_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    w.w_warehouse_name IS NOT NULL
GROUP BY w.w_warehouse_name
ORDER BY returned_amount DESC
LIMIT 10;
