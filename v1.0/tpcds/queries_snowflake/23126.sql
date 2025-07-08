
WITH RankedSales AS (
    SELECT 
        ss_customer_sk,
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk, ss_item_sk, ss_sold_date_sk
),
SalesSummary AS (
    SELECT 
        rs.ss_customer_sk,
        COUNT(DISTINCT rs.ss_item_sk) AS distinct_items,
        MAX(rs.total_sales) AS max_sales,
        MIN(rs.total_sales) AS min_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ss_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SalesAndDemographics AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.income_band,
        ss.distinct_items,
        ss.max_sales,
        ss.min_sales
    FROM 
        SalesSummary ss
    JOIN 
        CustomerInfo ci ON ss.ss_customer_sk = ci.c_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN max_sales IS NULL THEN 'No Sales'
        WHEN distinct_items > 10 THEN 'Frequent Buyer'
        WHEN income_band < 5 THEN 'Low Income'
        ELSE 'Regular Customer'
    END AS customer_category,
    CONCAT(c_first_name, ' ', c_last_name, ' - Sales: ', COALESCE(max_sales, 0)) AS customer_info
FROM 
    SalesAndDemographics
WHERE 
    (income_band > 0 OR income_band IS NULL)
    AND (max_sales > 100 OR distinct_items > 5)
ORDER BY 
    customer_category DESC,
    max_sales DESC
OFFSET (SELECT COUNT(*) FROM store_sales) % 100 LIMIT 50;
