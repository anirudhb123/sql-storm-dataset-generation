
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(sr.ticket_number) AS total_store_returns,
        COUNT(cr.order_number) AS total_catalog_returns,
        COUNT(wr.order_number) AS total_web_returns
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cu.c_customer_id
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS cu ON cd.cd_demo_sk = cu.c_current_cdemo_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(cr.total_store_returns + cr.total_catalog_returns + cr.total_web_returns) AS total_returns,
    COUNT(DISTINCT cu.c_customer_id) AS customer_count
FROM 
    CustomerDemographics AS cd
JOIN 
    CustomerReturns AS cr ON cd.c_customer_id = cr.c_customer_id
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_returns DESC, customer_count DESC;
