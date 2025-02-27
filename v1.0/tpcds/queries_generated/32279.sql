
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year < 1980
    
    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        sh.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN SalesHierarchy sh ON sh.c_customer_sk = c.c_current_addr_sk
    WHERE c.c_birth_year >= 1980
),
SalesData AS (
    SELECT 
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_orders,
        dd.d_year,
        s.s_store_name,
        ROW_NUMBER() OVER (PARTITION BY dd.d_year ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    GROUP BY dd.d_year, s.s_store_name
    HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
),
DemographicsSales AS (
    SELECT 
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.cd_marital_status,
        s.total_sales,
        s.total_orders,
        s.sales_rank
    FROM SalesHierarchy sh
    LEFT JOIN SalesData s ON s.sales_rank <= 10
)
SELECT 
    ds.c_first_name,
    ds.c_last_name,
    ds.cd_gender,
    ds.cd_marital_status,
    COALESCE(ds.total_sales, 0) AS sales_amount,
    ds.total_orders,
    CASE 
        WHEN ds.cd_gender = 'M' THEN 'Male'
        WHEN ds.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_label
FROM DemographicsSales ds
LEFT JOIN warehouse w ON w.w_warehouse_sk = (SELECT MIN(w_warehouse_sk) FROM warehouse)
WHERE ds.total_orders IS NOT NULL
ORDER BY ds.total_sales DESC, ds.c_first_name;
