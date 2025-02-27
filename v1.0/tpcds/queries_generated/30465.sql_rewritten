WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk < 1000  
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
    FROM customer AS c
    JOIN customer_hierarchy AS h ON c.c_customer_sk = h.c_customer_sk + 1  
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_paid_inc_tax) AS average_paid,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= 2450000  
    GROUP BY ws_bill_customer_sk
),

join_results AS (
    SELECT 
        h.c_first_name,
        h.c_last_name,
        h.cd_gender,
        h.cd_marital_status,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.average_paid, 0) AS average_paid,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM customer_hierarchy AS h
    LEFT JOIN sales_summary AS ss ON h.c_customer_sk = ss.ws_bill_customer_sk
)

SELECT 
    j.c_first_name,
    j.c_last_name,
    j.cd_gender,
    j.cd_marital_status,
    j.total_sales,
    j.average_paid,
    j.total_orders,
    CASE 
        WHEN j.total_sales > 1000 THEN 'High Value'
        WHEN j.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY j.cd_gender ORDER BY j.total_sales DESC) AS sales_rank
FROM join_results AS j
WHERE j.total_orders > 0
ORDER BY j.total_sales DESC;