
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_sales_per_order
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
demographic_analysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(ss_net_profit) AS total_profit
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    JOIN 
        store_sales ON ss_customer_sk = c_customer_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
income_band_analysis AS (
    SELECT 
        hd_income_band_sk,
        COUNT(DISTINCT hd_demo_sk) AS household_count,
        SUM(total_sales) AS total_income
    FROM 
        household_demographics
    JOIN 
        sales_summary ON hd_demo_sk = ws_bill_customer_sk
    GROUP BY 
        hd_income_band_sk
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    ib.hd_income_band_sk,
    ib.household_count,
    ib.total_income,
    da.customer_count,
    da.total_profit
FROM 
    demographic_analysis da
JOIN 
    income_band_analysis ib ON da.cd_demo_sk = ib.hd_demo_sk
WHERE 
    da.customer_count > 100
ORDER BY 
    ib.total_income DESC, da.total_profit DESC
LIMIT 10;
