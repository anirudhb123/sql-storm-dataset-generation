
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_addr_sk,
        0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_bill_customer_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd_purchase_estimate > (
        SELECT AVG(cd_purchase_estimate) FROM customer_demographics
    )
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.total_sales,
    ss.order_count,
    CASE
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM customer_hierarchy ch
LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN customer cd ON ch.c_customer_sk = cd.c_customer_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = ch.c_current_addr_sk
ORDER BY ch.level, total_sales DESC
LIMIT 100;
