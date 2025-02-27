
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity, 
        ws_sales_price, 
        ws_ext_sales_price 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        cs_order_number, 
        cs_quantity, 
        cs_sales_price, 
        cs_ext_sales_price 
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        COALESCE(cd_gender, 'U') AS gender,
        COALESCE(cd_marital_status, 'U') AS marital_status,
        COALESCE(cd_credit_rating, 'Unknown') AS credit_rating,
        hd_income_band_sk 
    FROM 
        customer 
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
    LEFT JOIN household_demographics ON hd_demo_sk = c_current_hdemo_sk
),
AggregatedSales AS (
    SELECT 
        C.gender,
        C.marital_status,
        C.credit_rating,
        SUM(S.ws_ext_sales_price) AS total_web_sales,
        SUM(S.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT S.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT S.cs_order_number) AS catalog_sales_count
    FROM 
        CustomerInfo C 
    LEFT JOIN SalesCTE S ON C.c_customer_sk = S.ws_order_number OR C.c_customer_sk = S.cs_order_number
    GROUP BY 
        C.gender, C.marital_status, C.credit_rating
)
SELECT 
    A.gender,
    A.marital_status,
    A.credit_rating,
    COALESCE(A.total_web_sales, 0) AS total_web_sales,
    COALESCE(A.total_catalog_sales, 0) AS total_catalog_sales,
    CASE 
        WHEN A.total_web_sales IS NULL AND A.total_catalog_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM 
    AggregatedSales A
WHERE 
    (A.total_web_sales > 10000 OR A.total_catalog_sales > 10000)
ORDER BY 
    A.gender, A.marital_status;
