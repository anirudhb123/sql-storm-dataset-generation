
WITH RECURSIVE StoreHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_manager,
        s_division_name,
        1 AS level
    FROM 
        store
    WHERE 
        s_manager IS NOT NULL

    UNION ALL

    SELECT 
        s_store_sk,
        CONCAT('Child of ', sh.s_store_name) AS s_store_name,
        sh.s_manager,
        sh.s_division_name,
        sh.level + 1
    FROM 
        StoreHierarchy sh
    JOIN 
        store s ON sh.s_store_sk = s.s_store_sk
    WHERE 
        sh.level < 3
),
CustomerReturns AS (
    SELECT 
        cr_returning_cdemo_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS total_order_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_cdemo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cu.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cr.total_returned, 0) AS total_returns,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer cu
    LEFT JOIN 
        CustomerReturns cr ON cu.c_customer_sk = cr.cr_returning_cdemo_sk
    LEFT JOIN 
        SalesData sd ON cu.c_customer_sk = sd.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS num_customers,
    AVG(cd.total_returns) AS avg_returns,
    AVG(cd.total_sales) AS avg_sales,
    AVG(cd.total_orders) AS avg_orders,
    (SELECT COUNT(DISTINCT c_customer_sk) FROM customer WHERE c_birth_year = 1990) AS total_customers_born_1990
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    num_customers DESC;
