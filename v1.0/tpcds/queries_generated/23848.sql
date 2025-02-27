
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate > 10000 THEN 'HIGH VALUE'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'MEDIUM VALUE'
            ELSE 'LOW VALUE'
        END AS purchase_value_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopReturningCustomers AS (
    SELECT 
        cr.s_customer_sk,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.purchase_value_category
    FROM 
        RankedReturns cr
    JOIN 
        CustomerDemographics cd ON cr.s_customer_sk = cd.c_customer_sk
    WHERE 
        cr.return_rank = 1
)
SELECT 
    tc.c_customer_sk,
    COUNT(DISTINCT sr.s_item_sk) AS items_returned,
    SUM(sr.s_return_quantity) AS total_returned_quantity,
    AVG(sr.s_return_amt) AS avg_return_amount,
    MAX(sr.s_return_amt) AS max_return_amount,
    MIN(sr.s_return_amt) AS min_return_amount,
    STRING_AGG(DISTINCT concat(i.i_item_desc, ' - ', i.i_current_price) ORDER BY i.i_item_desc) AS returned_items,
    cd.cd_gender,
    cd.purchase_value_category
FROM 
    TopReturningCustomers tc
LEFT JOIN 
    store_returns sr ON tc.s_customer_sk = sr.s_customer_sk
LEFT JOIN 
    item i ON sr.s_item_sk = i.i_item_sk
GROUP BY 
    tc.c_customer_sk, cd.cd_gender, cd.purchase_value_category
HAVING 
    SUM(sr.s_return_amt) IS NOT NULL
ORDER BY 
    total_returned_quantity DESC, total_returned_amount ASC;
