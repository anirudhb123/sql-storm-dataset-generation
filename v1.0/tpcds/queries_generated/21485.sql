
WITH RECURSIVE customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL AND cd.cd_gender IN ('M', 'F')
),
ranked_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ca.ca_city,
        CA.ca_state,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS marital_rank
    FROM customer_data cd
    LEFT JOIN customer_address ca ON cd.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.rank_by_purchase <= 10
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
combined_sales AS (
    SELECT 
        wc.c_first_name,
        wc.c_last_name,
        w.total_sales,
        w.total_profit,
        CASE 
            WHEN w.total_sales > 100 THEN 'High Performer'
            WHEN w.total_sales BETWEEN 50 AND 100 THEN 'Moderate Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM ranked_customers wc
    FULL OUTER JOIN warehouse_sales w ON wc.c_customer_sk = w.w_warehouse_sk AND wc.marital_rank = 1
)
SELECT
    c.c_first_name,
    c.c_last_name,
    w.total_sales,
    w.total_profit,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(w.performance_category, 'No Performance Data') AS performance_category,
    CASE 
        WHEN w.total_profit IS NULL THEN 'Profit Data Unavailable'
        ELSE CONCAT('$', ROUND(w.total_profit, 2))
    END AS formatted_profit
FROM combined_sales w
JOIN customer_data c ON c.c_customer_sk = w.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE (c.c_birth_month = 6 AND c.c_birth_day IS NOT NULL) OR (c.c_birth_month IS NULL AND c.c_birth_day = 15)
ORDER BY city, performance_category DESC;
