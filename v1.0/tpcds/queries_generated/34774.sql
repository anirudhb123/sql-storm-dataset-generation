
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk AND ch.level < 3
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_id,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
returns_summary AS (
    SELECT 
        sr_cdemo_sk AS customer_id,
        SUM(sr_return_amt_inc_tax) AS total_returns,
        COUNT(sr_ticket_number) AS total_returns_count
    FROM store_returns
    GROUP BY sr_cdemo_sk
),
combined_summary AS (
    SELECT 
        cs.customer_id,
        cs.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        cs.total_orders,
        rs.total_returns_count
    FROM sales_summary cs
    LEFT JOIN returns_summary rs ON cs.customer_id = rs.customer_id
),
customer_details AS (
    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE WHEN cd.cd_settings IS NOT NULL THEN 'Active' ELSE 'Inactive' END AS status,
        coalesce(cs.total_sales, 0) - coalesce(cs.total_returns, 0) AS net_revenue
    FROM customer_hierarchy ch
    LEFT JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN combined_summary cs ON ch.c_customer_sk = cs.customer_id
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    (CASE 
        WHEN net_revenue > 1000 THEN 'High Value'
        WHEN net_revenue BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
     END) AS customer_value,
    SUM(cd.net_revenue) OVER (PARTITION BY cd.cd_gender ORDER BY cd.c_last_name) AS cumulative_revenue_by_gender
FROM customer_details cd
WHERE cd.status = 'Active'
AND cd.c_first_name IS NOT NULL
ORDER BY cd.c_last_name;
