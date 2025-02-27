
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451003 AND 2451387 -- Example date range
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_income_band_sk IS NULL THEN 'Unknown'
            WHEN cd.cd_income_band_sk >= 1 AND cd.cd_income_band_sk <= 4 THEN 'Low Income'
            WHEN cd.cd_income_band_sk > 4 AND cd.cd_income_band_sk <= 10 THEN 'Medium Income'
            ELSE 'High Income' 
        END AS income_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cd.cd_gender,
        cd.income_category,
        RANK() OVER (PARTITION BY cd.income_category ORDER BY total_sales DESC) AS rank_within_income
    FROM 
        RankedSales cs
    JOIN 
        CustomerDemo cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
),
FinalReport AS (
    SELECT 
        sa.c_customer_sk,
        sa.total_sales,
        sa.cd_gender,
        sa.income_category,
        sa.rank_within_income,
        CASE 
            WHEN sa.rank_within_income <= 3 THEN 'Top Performer'
            ELSE 'Other'
        END AS performance_category
    FROM 
        SalesAnalysis sa
)
SELECT 
    fr.c_customer_sk,
    fr.total_sales,
    fr.cd_gender,
    fr.income_category,
    fr.performance_category,
    CASE 
        WHEN fr.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC NULLS LAST;
