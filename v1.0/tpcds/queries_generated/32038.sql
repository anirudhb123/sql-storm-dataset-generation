
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        s.ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk DESC) AS rank
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
RecentSales AS (
    SELECT 
        sh.c_customer_sk,
        CONCAT(sh.c_first_name, ' ', sh.c_last_name) AS full_name,
        sh.ss_sales_price
    FROM SalesHierarchy sh
    WHERE sh.rank = 1
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS potential
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
FinalReport AS (
    SELECT 
        rs.full_name,
        SUM(rs.ss_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.potential
    FROM RecentSales rs
    JOIN customer c ON rs.c_customer_sk = c.c_customer_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY rs.full_name, cd.cd_gender, cd.cd_marital_status, cd.potential
)
SELECT 
    fr.full_name,
    fr.total_sales,
    CASE 
        WHEN fr.total_sales > 1000 THEN 'High Value'
        WHEN fr.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.potential
FROM FinalReport fr
JOIN customer_demographics cd ON cd.cd_demo_sk IN (
    SELECT cd_demo_sk 
    FROM customer_demographics 
    WHERE cd_purchase_estimate IS NOT NULL
    INTERSECT
    SELECT c.c_current_cdemo_sk 
    FROM customer c
)
ORDER BY fr.total_sales DESC
LIMIT 100;
