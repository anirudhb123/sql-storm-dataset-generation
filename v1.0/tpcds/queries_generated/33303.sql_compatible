
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        1 AS level
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ch.level + 1
    FROM 
        CustomerHierarchy ch
        JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500 AND ch.level < 5
),
SalesData AS (
    SELECT 
        cs.cs_customer_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        COUNT(cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_customer_sk
),
FilteredSales AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_marital_status,
        ch.cd_gender,
        ch.cd_purchase_estimate,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerHierarchy ch
        LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.cs_customer_sk
    WHERE 
        sd.total_sales IS NOT NULL AND
        (ch.cd_gender = 'F' OR ch.cd_marital_status = 'M')
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    CASE 
        WHEN f.total_sales > 10000 THEN 'High Value'
        WHEN f.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(f.order_count, 0) AS total_orders,
    CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name
FROM 
    FilteredSales f
WHERE 
    f.total_sales IS NOT NULL
ORDER BY 
    customer_value DESC, 
    f.total_orders DESC;
