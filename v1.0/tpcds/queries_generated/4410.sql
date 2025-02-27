
WITH demographic_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
), 
sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.bill_customer_sk
), 
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_profit, 0) AS total_profit,
        ds.total_dependents
    FROM customer c
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.bill_customer_sk
    LEFT JOIN demographic_summary ds ON c.c_current_cdemo_sk = ds.cd_demo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_profit,
    cs.total_dependents,
    CASE 
        WHEN cs.total_profit >= 1000 THEN 'High Value'
        WHEN cs.total_profit BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    string_agg(DISTINCT CONCAT(cc.cc_manager, ' (', cc.cc_name, ')'), ', ') AS call_center_managers
FROM customer_sales cs
LEFT JOIN call_center cc ON cs.c_customer_sk = cc.cc_call_center_sk
GROUP BY cs.c_customer_sk, cs.total_orders, cs.total_profit, cs.total_dependents
HAVING COUNT(cc.cc_manager) > 1
ORDER BY cs.total_profit DESC;
