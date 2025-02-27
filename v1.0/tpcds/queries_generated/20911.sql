
WITH RankedStoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE CAST(cd_income_band_sk AS VARCHAR)
        END AS income_band,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_demo_sk) AS gender_rank
    FROM 
        customer_demographics
),
FilteredSales AS (
    SELECT 
        ss.ss_store_sk,
        ss.ss_net_paid,
        ss.ss_sold_date_sk,
        sd.latitude,
        sd.longitude
    FROM 
        store_sales ss
    LEFT JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    LEFT JOIN 
        (SELECT 
            w.w_warehouse_sk, 
            ROUND(DBMS_RANDOM.VALUE, 4) AS latitude, 
            ROUND(DBMS_RANDOM.VALUE, 4) AS longitude
          FROM 
            warehouse w) sd ON sd.w_warehouse_sk = w.w_warehouse_sk
),
SalesVariance AS (
    SELECT 
        f.ss_store_sk,
        f.ss_net_paid,
        f.ss_sold_date_sk,
        COALESCE(RANK() OVER (PARTITION BY f.ss_store_sk ORDER BY f.ss_net_paid), 0) AS sales_rank
    FROM 
        FilteredSales f
    WHERE 
        f.ss_net_paid > (SELECT AVG(ss_net_paid) FROM store_sales)
)
SELECT 
    c.cd_demo_sk,
    c.cd_gender,
    c.income_band,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.sales_count, 0) AS sales_count,
    AVG(sv.ss_net_paid) AS average_net_paid,
    COUNT(DISTINCT c.gender_rank) AS unique_genders,
    CASE 
        WHEN COUNT(sv.ss_net_paid) = 0 THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    CustomerDemographics c
LEFT JOIN 
    RankedStoreSales s ON c.cd_demo_sk = s.ss_store_sk
LEFT JOIN 
    SalesVariance sv ON c.cd_demo_sk = sv.ss_store_sk
WHERE 
    c.cd_marital_status IN ('M', 'S') 
    AND c.cd_gender IS NOT NULL
GROUP BY 
    c.cd_demo_sk, c.cd_gender, c.income_band
ORDER BY 
    total_sales DESC, unique_genders DESC, average_net_paid
FETCH FIRST 100 ROWS ONLY;
