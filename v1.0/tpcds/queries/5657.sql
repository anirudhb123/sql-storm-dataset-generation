
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_return
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS demo_count
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender
    ORDER BY 
        demo_count DESC
    LIMIT 5
)
SELECT 
    cr.c_customer_id,
    cr.web_return_count,
    cr.store_return_count,
    cr.total_web_return,
    cr.total_store_return,
    td.cd_gender,
    td.demo_count
FROM 
    CustomerReturns cr
JOIN 
    TopDemographics td ON cr.c_customer_id IN (
        SELECT 
            c.c_customer_id 
        FROM 
            customer c 
        JOIN 
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
        WHERE 
            cd.cd_gender = td.cd_gender
    )
ORDER BY 
    cr.total_web_return DESC, 
    cr.total_store_return DESC;
