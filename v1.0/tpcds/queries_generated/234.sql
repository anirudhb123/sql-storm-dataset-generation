
WITH RankedSales AS (
    SELECT 
        ss_customer_sk,
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk, ss_store_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd_cd.gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopSales AS (
    SELECT 
        r.ss_customer_sk,
        r.ss_store_sk,
        r.total_sales,
        cd.gender,
        cd.marital_status,
        cd.income_band
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.ss_customer_sk = cd.c_customer_sk
    WHERE 
        r.sales_rank <= 10 -- Get top 10 sales per store
)
SELECT 
    ts.ss_store_sk,
    COUNT(DISTINCT ts.ss_customer_sk) AS unique_customers,
    AVG(ts.total_sales) AS average_sales,
    COUNT(CASE WHEN ts.gender = 'F' THEN 1 END) AS female_customers,
    COUNT(CASE WHEN ts.gender = 'M' THEN 1 END) AS male_customers,
    COUNT(DISTINCT CASE WHEN ts.income_band IS NULL THEN ts.ss_customer_sk END) AS customers_no_income_band
FROM 
    TopSales ts
GROUP BY 
    ts.ss_store_sk
ORDER BY 
    unique_customers DESC;
