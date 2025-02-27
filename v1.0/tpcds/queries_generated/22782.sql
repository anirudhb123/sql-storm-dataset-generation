
WITH RECURSIVE address_tree AS (
    SELECT 
        ca_address_sk,
        ca_city,
        1 AS level,
        ca_street_number || ' ' || ca_street_name AS full_address
    FROM customer_address
    WHERE ca_state = 'CA'

    UNION ALL

    SELECT 
        ca2.ca_address_sk,
        ca2.ca_city,
        at.level + 1,
        at.full_address || ' -> ' || ca2.ca_street_number || ' ' || ca2.ca_street_name
    FROM customer_address ca2
    JOIN address_tree at ON ca2.ca_city = at.ca_city AND ca2.ca_address_sk != at.ca_address_sk
    WHERE at.level < 5
),
customer_counts AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY cd_gender
),
sales_summary AS (
    SELECT
        sm_code,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    JOIN ship_mode ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    WHERE ws_sold_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 0 AND d_current_week = '1'
    )
    GROUP BY sm_code
),
ranked_sales AS (
    SELECT 
        sm_code,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    at.full_address,
    cc.cd_gender,
    cc.customer_count,
    rs.sm_code,
    rs.total_sales,
    rs.order_count,
    CASE 
        WHEN rs.sales_rank <= 5 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_status
FROM address_tree at
CROSS JOIN customer_counts cc
LEFT JOIN ranked_sales rs ON cc.customer_count > 10
WHERE cc.customer_count IS NOT NULL
ORDER BY at.level, cc.cd_gender, rs.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
