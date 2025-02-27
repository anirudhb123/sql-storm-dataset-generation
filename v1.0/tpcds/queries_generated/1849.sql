
WITH customer_return_metrics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_return_quantity) AS total_web_return_quantity
    FROM 
        web_returns wr
    INNER JOIN 
        customer c ON wr.returning_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
store_return_metrics AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(sr_return_quantity) AS total_store_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
combined_returns AS (
    SELECT 
        crm.c_customer_sk,
        COALESCE(crm.total_web_returns, 0) AS web_returns,
        COALESCE(srm.total_store_returns, 0) AS store_returns,
        crm.total_web_return_amount,
        srm.total_store_return_amount,
        CRM.total_web_return_quantity,
        srm.total_store_return_quantity
    FROM 
        customer_return_metrics crm
    FULL OUTER JOIN 
        store_return_metrics srm ON crm.c_customer_sk = srm.sr_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
ranked_customer_data AS (
    SELECT 
        cr.c_customer_sk,
        cr.web_returns,
        cr.store_returns,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_web_return_amount DESC) AS gender_rank
    FROM 
        combined_returns cr
    JOIN 
        customer_demographics cd ON cr.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    cc.c_customer_sk,
    cc.web_returns,
    cc.store_returns,
    cd.cd_gender,
    cd.cd_marital_status,
    cc.total_web_return_amount,
    cc.total_store_return_amount,
    CASE 
        WHEN cc.web_returns > cc.store_returns THEN 'Web' 
        WHEN cc.store_returns > cc.web_returns THEN 'Store'
        ELSE 'Equal'
    END AS preferred_return_channel,
    cc.gender_rank
FROM 
    ranked_customer_data cc
WHERE 
    cc.gender_rank <= 5
ORDER BY 
    cc.total_web_return_amount DESC, 
    cc.store_returns DESC;
