
WITH CustomerReturns AS (
    SELECT 
        sr_store_sk, 
        sr_cdemo_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk, sr_cdemo_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(hd.hd_dep_count) AS dependent_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, hd.hd_income_band_sk, hd.hd_buy_potential
),
ReturnsSummary AS (
    SELECT 
        cr.sr_store_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.hd_income_band_sk,
        cd.hd_buy_potential,
        SUM(cr.total_returns) AS total_returns,
        SUM(cr.total_return_value) AS total_return_value
    FROM 
        CustomerReturns cr
    INNER JOIN 
        CustomerDemographics cd ON cr.sr_cdemo_sk = cd.c_customer_sk
    GROUP BY 
        cr.sr_store_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, cd.hd_income_band_sk, cd.hd_buy_potential
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk
)
SELECT 
    rs.sr_store_sk,
    COALESCE(s.total_sales, 0) AS total_sales_last_30_days,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_value, 0) AS total_return_value,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.cd_purchase_estimate,
    rs.cd_credit_rating,
    rs.hd_income_band_sk,
    rs.hd_buy_potential
FROM 
    ReturnsSummary rs
LEFT JOIN 
    StoreInfo s ON rs.sr_store_sk = s.s_store_sk
ORDER BY 
    total_return_value DESC, total_returns DESC;
