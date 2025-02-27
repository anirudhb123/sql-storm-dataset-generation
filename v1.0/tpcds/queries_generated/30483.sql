
WITH RECURSIVE revenue_cte AS (
    SELECT 
        'Initial' AS revenue_source,
        ws_sold_date_sk,
        SUM(ws_sales_price * ws_quantity) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_sold_date_sk

    UNION ALL

    SELECT 
        'Previous' AS revenue_source,
        ws_sold_date_sk,
        SUM(ws_sales_price * ws_quantity) * 0.9 AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_sold_date_sk
),
average_revenue AS (
    SELECT 
        d.d_year,
        SUM(re.total_revenue) AS year_revenue,
        AVG(re.total_revenue) AS avg_daily_revenue,
        COUNT(DISTINCT re.total_orders) AS total_orders_in_year
    FROM revenue_cte re
    JOIN date_dim d ON re.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        SUM(ws.net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status
)
SELECT 
    a.d_year,
    AVG(a.avg_daily_revenue) AS avg_revenue,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    COUNT(DISTINCT CASE WHEN c.cd_marital_status = 'M' THEN c.c_customer_sk END) AS married_customers,
    SUM(COALESCE(c.total_profit, 0)) AS total_customer_profit
FROM average_revenue a
LEFT JOIN customer_data c ON a.year_revenue > 1000000
WHERE a.year_revenue IS NOT NULL
GROUP BY a.d_year
ORDER BY a.d_year DESC;
