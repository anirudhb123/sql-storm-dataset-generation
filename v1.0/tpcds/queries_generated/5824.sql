
WITH customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        cm.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.total_purchases,
        cm.total_spent,
        RANK() OVER (ORDER BY cm.total_spent DESC) AS rnk
    FROM customer_metrics cm
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_purchases,
    tc.total_spent,
    cd.cc_market_class,
    cd.cc_market_manager,
    COUNT(DISTINCT ss.ss_store_sk) AS unique_stores
FROM top_customers tc
JOIN call_center cd ON cd.cc_call_center_sk = (SELECT MIN(cc_call_center_sk) FROM call_center)
WHERE rnk <= 10
GROUP BY tc.c_first_name, tc.c_last_name, tc.total_purchases, tc.total_spent, cd.cc_market_class, cd.cc_market_manager
ORDER BY tc.total_spent DESC;
