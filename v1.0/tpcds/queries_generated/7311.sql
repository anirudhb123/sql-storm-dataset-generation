
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(sr.sr_item_sk) AS returns_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr.sr_return_quantity) AS total_returned_quantity
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_age BETWEEN 25 AND 45
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_credit_rating, 
        hd.hd_income_band_sk
)
SELECT 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status,
    ci.cd_credit_rating,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ci.returns_count,
    ci.total_returned_amount,
    ci.total_returned_quantity
FROM 
    customer_info ci
LEFT JOIN 
    income_band ib ON ci.income_band = ib.ib_income_band_sk
ORDER BY 
    ci.total_returned_amount DESC
LIMIT 100;
