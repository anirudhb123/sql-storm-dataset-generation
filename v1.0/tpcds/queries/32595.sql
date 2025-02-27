
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_current_addr_sk,
        1 AS level
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_current_addr_sk,
        sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_addr_sk = sh.c_current_addr_sk
    WHERE sh.level < 3
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
revenue_by_age_group AS (
    SELECT 
        CASE 
            WHEN c.c_birth_year >= 1980 THEN 'Millennials'
            WHEN c.c_birth_year BETWEEN 1965 AND 1979 THEN 'Gen X'
            WHEN c.c_birth_year < 1965 THEN 'Baby Boomers'
            ELSE 'Unknown'
        END AS age_group,
        SUM(sd.total_sales) AS total_revenue
    FROM sales_data sd
    JOIN customer c ON sd.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY age_group
),
popular_items AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
    ORDER BY total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    r.age_group,
    r.total_revenue,
    pi.i_item_id,
    pi.total_quantity_sold
FROM revenue_by_age_group r
LEFT JOIN popular_items pi ON pi.total_quantity_sold > 100
ORDER BY r.total_revenue DESC, pi.total_quantity_sold DESC;
