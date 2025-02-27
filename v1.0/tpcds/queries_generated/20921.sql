
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned,
        SUM(cr.return_amt_inc_tax) AS total_returned_amt,
        COALESCE(NULLIF(SUM(cr.return_tax), 0), NULL) AS total_return_tax
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cr.returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.gender,
        CASE 
            WHEN cd.marital_status = 'M' AND cd.dep_count > 0 THEN 'Married With Dependencies'
            WHEN cd.marital_status = 'S' AND cd.dep_count = 0 THEN 'Single Without Dependencies'
            ELSE 'Other'
        END AS marital_status_category
    FROM 
        customer_demographics cd
),
TopCustomers AS (
    SELECT 
        cr.returning_customer_sk,
        cd.gender,
        cd.marital_status_category,
        cr.total_returned,
        cr.total_returned_amt,
        ROW_NUMBER() OVER (PARTITION BY cd.gender ORDER BY cr.total_returned_amt DESC) AS rn
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.returning_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_returned_amt > (SELECT AVG(total_returned_amt) FROM CustomerReturns)
)
SELECT 
    tc.returning_customer_sk,
    tc.gender,
    tc.marital_status_category,
    tc.total_returned,
    tc.total_returned_amt
FROM 
    TopCustomers tc
WHERE 
    tc.rn <= 5
UNION ALL
SELECT 
    -1 AS returning_customer_sk, 
    'N/A' AS gender, 
    'N/A' AS marital_status_category, 
    0 AS total_returned, 
    SUM(CASE WHEN cr.return_quantity IS NULL THEN 0 ELSE cr.return_quantity END) 
        / NULLIF(SUM(CASE WHEN cr.return_quantity IS NULL THEN 1 ELSE NULL END), 0) AS total_returned_amt
FROM 
    catalog_returns cr
WHERE 
    cr.returning_customer_sk IS NULL
HAVING 
    COUNT(*) > 0
ORDER BY 
    total_returned_amt DESC;
