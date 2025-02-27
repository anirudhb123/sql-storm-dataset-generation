
WITH customer_metrics AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = c.c_customer_sk 
           AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2460000) AS total_store_sales,
        (SELECT SUM(ws.ws_quantity)
         FROM web_sales ws
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY (SELECT NULL)) AS marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
    WHERE 
        ca.ca_state IN ('CA', 'NY') 
        AND (cd.cd_credit_rating IS NULL OR cd.cd_credit_rating = 'Low')
        AND (c.c_birth_day = 29 AND c.c_birth_month = 2 AND c.c_birth_year % 4 = 0) 
        OR (c.c_birth_month <> 2 AND c.c_birth_day <= 30)
), 
sales_summary AS (
    SELECT 
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store'
            WHEN total_web_sales > total_store_sales THEN 'Web'
            ELSE 'Equal'
        END AS preferred_channel,
        COUNT(*) AS customer_count,
        AVG(total_store_sales) AS avg_store_sales,
        AVG(total_web_sales) AS avg_web_sales
    FROM 
        customer_metrics
    GROUP BY 
        preferred_channel
)
SELECT 
    ps.preferred_channel,
    ps.customer_count,
    ps.avg_store_sales,
    ps.avg_web_sales,
    (SELECT COUNT(*) FROM customer WHERE c_cust_id IS NULL) AS null_customers,
    (SELECT MIN(cd.cd_purchase_estimate) 
     FROM customer_demographics cd 
     WHERE cd.cd_dep_count IS NOT NULL) AS min_dep_purchase_estimate,
    (SELECT MAX(w.w_warehouse_name) 
     FROM warehouse w 
     WHERE w.w_warehouse_sq_ft IS NOT NULL) AS max_warehouse_name
FROM 
    sales_summary ps
UNION ALL
SELECT 
    'Combined' AS preferred_channel,
    SUM(customer_count) AS customer_count,
    SUM(avg_store_sales) AS avg_store_sales,
    SUM(avg_web_sales) AS avg_web_sales
FROM 
    sales_summary
GROUP BY 
    1
HAVING 
    SUM(customer_count) > 10
ORDER BY 
    1;
