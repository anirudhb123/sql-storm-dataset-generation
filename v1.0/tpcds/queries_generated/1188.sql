
WITH CustomerReturns AS (
    SELECT 
        cr.returned_date_sk,
        cr.returned_time_sk,
        cr.return_item_sk,
        cr.returning_customer_sk,
        cr.return_quantity,
        cr.return_amount,
        cr.return_tax,
        cr.return_amt_inc_tax,
        cr.returned_customer_sk,
        cr.order_number,
        cr.call_center_sk,
        cr.store_sk,
        cr.catalog_page_sk,
        CASE 
            WHEN cr.return_quantity > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM catalog_returns cr
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer_demographics cd
), ReturnsSummary AS (
    SELECT 
        CASE 
            WHEN cr.returned_date_sk IS NULL THEN 'No Returns'
            ELSE 'With Returns'
        END AS return_summary,
        COUNT(DISTINCT cr.returning_customer_sk) AS unique_returning_customers,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.return_amount) AS total_return_amount,
        AVG(cr.return_tax) AS avg_return_tax
    FROM CustomerReturns cr
    GROUP BY return_summary
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(cr.return_quantity) AS total_returned_quantity,
    COALESCE(SUM(cr.return_amount), 0) AS total_returned_amount,
    COUNT(DISTINCT cr.returning_customer_sk) AS unique_return_customers,
    RANK() OVER (ORDER BY SUM(cr.return_quantity) DESC) AS return_rank,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM customer c
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_birth_year IS NOT NULL
GROUP BY c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
HAVING SUM(cr.return_quantity) > 0
ORDER BY total_returned_quantity DESC
LIMIT 50;
