
WITH RecursiveCustomer AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_preferred_cust_flag,
        cd_income_band_sk,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        cd.ib_income_band_sk,
        rc.level + 1
    FROM 
        customer c
    JOIN 
        RecursiveCustomer rc ON c.c_customer_sk = rc.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.ib_income_band_sk IS NOT NULL AND 
        rc.level < 3
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1975 AND 1995
    GROUP BY 
        c.c_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        ss.ss_customer_sk
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_web_sales,
    COALESCE(sst.total_store_sales, 0) AS total_store_sales,
    COALESCE(ss.total_sales, 0) + COALESCE(sst.total_store_sales, 0) AS total_combined_sales
FROM 
    RecursiveCustomer rc
LEFT JOIN 
    SalesSummary ss ON rc.c_customer_sk = ss.c_customer_sk
LEFT JOIN 
    StoreSalesSummary sst ON rc.c_customer_sk = sst.ss_customer_sk
WHERE 
    rc.level = 1 
    AND (total_combined_sales > 0 OR rc.c_preferred_cust_flag = 'Y')
ORDER BY 
    total_combined_sales DESC
FETCH FIRST 100 ROWS ONLY;
