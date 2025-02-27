
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rank
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk BETWEEN (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 10
        ) - 30 AND 
        (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 10
        )
    GROUP BY 
        cr_returning_customer_sk, cr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE
            WHEN cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category
    FROM 
        customer_demographics
    WHERE 
        cd_credit_rating IS NOT NULL
),
HighReturnCustomers AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.total_return_quantity) AS total_quantity_returned
    FROM 
        RankedReturns cr
    WHERE 
        cr.rank <= 5
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.purchase_estimate_category,
    SUM(CASE WHEN ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231 THEN ss.ss_net_paid END) AS total_net_paid,
    COALESCE(COUNT(DISTINCT sr.sr_ticket_number), 0) AS total_store_returns,
    COALESCE(MAX(s.s_store_name), 'No Store') AS store_name
FROM 
    customer c
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
JOIN 
    HighReturnCustomers hrc ON hrc.returning_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_customer_id, cd.purchase_estimate_category
HAVING 
    SUM(ss.ss_net_paid) IS NOT NULL 
    AND COUNT(DISTINCT ss.ss_ticket_number) > 3
ORDER BY 
    total_net_paid DESC NULLS LAST;
