
WITH CustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_items,
        SUM(cr.return_amount) AS total_returned_amount,
        MAX(cr.returned_date_sk) AS last_return_date_sk
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
WebReturns AS (
    SELECT
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_returned_items,
        SUM(wr.return_amt) AS total_returned_amount,
        MAX(wr.returned_date_sk) AS last_return_date_sk
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
),
CombinedReturns AS (
    SELECT
        cr.returning_customer_sk,
        COALESCE(cr.total_returned_items, 0) AS total_catalog_returned_items,
        COALESCE(cr.total_returned_amount, 0) AS total_catalog_returned_amount,
        COALESCE(wr.total_returned_items, 0) AS total_web_returned_items,
        COALESCE(wr.total_returned_amount, 0) AS total_web_returned_amount
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr ON cr.returning_customer_sk = wr.returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cr.total_catalog_returned_items + wr.total_web_returned_items, 0) AS total_returns
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CombinedReturns cr ON c.c_customer_sk = cr.returning_customer_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(cd.c_customer_sk) AS total_customers,
    AVG(total_returns) AS average_return_count
FROM CustomerDemographics cd
GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY average_return_count DESC;
