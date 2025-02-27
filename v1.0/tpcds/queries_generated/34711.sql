
WITH RECURSIVE sales_analysis AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
high_value_customers AS (
    SELECT
        cd_demo_sk,
        SUM(ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ws_sales_price > 100
    GROUP BY
        cd_demo_sk
    HAVING
        total_spent > 1000
),
avg_sales AS (
    SELECT
        ws.web_site_sk,
        AVG(ws_sales_price) AS avg_web_sales
    FROM
        web_sales ws
    GROUP BY
        ws.web_site_sk
),
top_ship_modes AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_type,
        COUNT(*) AS mode_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS mode_rank
    FROM
        web_sales ws
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        sm.sm_ship_mode_sk, sm.sm_type
    HAVING
        COUNT(*) > 50
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(s.total_quantity, 0) AS total_web_sales_quantity,
    COALESCE(s.total_sales, 0) AS total_web_sales_value,
    COALESCE(h.total_spent, 0) AS high_value_spent,
    a.avg_web_sales,
    T.sm_type AS popular_ship_mode
FROM
    customer c
LEFT JOIN
    sales_analysis s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN
    high_value_customers h ON c.c_current_cdemo_sk = h.cd_demo_sk
JOIN
    avg_sales a ON a.web_site_sk = c.c_current_addr_sk -- assuming this join is sensible for benchmarks
LEFT JOIN
    (SELECT sm_type FROM top_ship_modes WHERE mode_rank = 1) T ON 1=1
WHERE
    c.c_preferred_cust_flag = 'Y'
    AND (c.c_birth_day IS NOT NULL OR c.c_birth_month IS NOT NULL)
ORDER BY
    total_web_sales_value DESC
LIMIT 100;
