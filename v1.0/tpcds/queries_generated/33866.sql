
WITH RECURSIVE sales_by_customer AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        COALESCE(SUM(ss_net_paid), 0) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count
    FROM customer 
    LEFT JOIN store_sales ON c_customer_sk = ss_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(SUM(ws_net_paid), 0) + total_sales AS total_sales,
        COUNT(ws_order_number) + sales_count AS sales_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws_ship_customer_sk
    JOIN sales_by_customer sbc ON c.c_customer_sk = sbc.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, total_sales
),
demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics 
    GROUP BY cd_gender, cd_marital_status
),
max_sales AS (
    SELECT 
        c_customer_sk, 
        MAX(total_sales) AS max_total_sales
    FROM sales_by_customer
    GROUP BY c_customer_sk
)
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    sbc.total_sales,
    CASE 
        WHEN sbc.total_sales > 1000 THEN 'High Value Customer' 
        WHEN sbc.total_sales > 500 THEN 'Medium Value Customer' 
        ELSE 'Low Value Customer' 
    END AS customer_value
FROM sales_by_customer sbc 
JOIN customer c ON sbc.c_customer_sk = c.c_customer_sk 
LEFT JOIN demographics d ON d.cd_marital_status = 'M' AND d.cd_gender = 'F'
JOIN max_sales ms ON sbc.c_customer_sk = ms.c_customer_sk 
WHERE sbc.total_sales IS NOT NULL 
ORDER BY sbc.total_sales DESC
LIMIT 100;

