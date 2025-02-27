
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_sales = SUM(ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s_store_sk, s_store_name, s_number_employees
),
TopStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        total_sales
    FROM SalesHierarchy
    WHERE rank <= 5
),
CustomerEducation AS (
    SELECT 
        cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_education_status
),
SalesByEducation AS (
    SELECT 
        ce.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN CustomerEducation ce ON ce.customer_count > 0
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ce.cd_education_status
),
FinalReport AS (
    SELECT 
        ts.s_store_name,
        ts.total_sales,
        se.cd_education_status,
        se.total_sales AS education_sales
    FROM TopStores ts
    FULL OUTER JOIN SalesByEducation se ON ts.s_store_sk = se.cd_education_status
)
SELECT 
    COALESCE(f.s_store_name, 'Overall Total') AS store,
    COALESCE(f.total_sales, 0) AS store_sales,
    COALESCE(f.education_sales, 0) AS education_sales,
    (COALESCE(f.total_sales, 0) - COALESCE(f.education_sales, 0)) AS difference
FROM FinalReport f
ORDER BY f.store_sales DESC;
