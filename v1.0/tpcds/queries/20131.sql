
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS average_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales,
    ss.order_count,
    ss.average_net_paid,
    COALESCE(ss.total_sales / NULLIF(ss.order_count, 0), 0) AS average_sales_per_order,
    CASE 
        WHEN ci.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status_label
FROM sales_summary ss
JOIN customer_info ci ON ss.ws_item_sk = ci.c_current_cdemo_sk
LEFT JOIN reason r ON r.r_reason_sk = (SELECT MAX(sr_reason_sk) FROM store_returns sr WHERE sr_customer_sk = ci.c_customer_sk)
WHERE ci.gender_rnk <= 10
ORDER BY ss.total_sales DESC
LIMIT 100;
