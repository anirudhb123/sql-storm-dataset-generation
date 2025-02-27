
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451547  -- Arbitrary date range
    GROUP BY 
        ws_bill_cdemo_sk
), demographic_analysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.order_count,
        ss.avg_net_profit
    FROM 
        customer_demographics cd 
    LEFT JOIN 
        sales_summary ss ON cd.cd_demo_sk = ss.customer_demo_sk
), income_distribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(cd.cd_demo_sk) AS demographic_count,
        SUM(da.total_sales) AS total_income_sales
    FROM 
        household_demographics hd 
    LEFT JOIN 
        demographic_analysis da ON hd.hd_demo_sk = da.customer_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(id.demographic_count, 0) AS demographic_count,
    COALESCE(id.total_income_sales, 0) AS total_income_sales
FROM 
    income_band ib 
LEFT JOIN 
    income_distribution id ON ib.ib_income_band_sk = id.hd_income_band_sk
ORDER BY 
    ib.ib_lower_bound;
