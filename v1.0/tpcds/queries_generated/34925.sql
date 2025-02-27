
WITH RECURSIVE sales_hierarchy AS (
    SELECT s.s_store_sk, s.s_store_name, s.s_country, 0 AS level
    FROM store s
    WHERE s.s_store_sk IN (SELECT DISTINCT sr_store_sk FROM store_returns)
    
    UNION ALL
    
    SELECT s.s_store_sk, s.s_store_name, s.s_country, sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE s.s_country IS NOT NULL AND sh.level < 3
),
current_year_sales AS (
    SELECT 
        ws.sold_date_sk,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY ws.sold_date_sk
),
previous_year_sales AS (
    SELECT 
        d.d_date_sk,
        SUM(ws.ws_net_profit) AS total_sales_prev,
        COUNT(ws.ws_order_number) AS order_count_prev,
        AVG(ws.ws_net_paid) AS avg_order_value_prev
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
    GROUP BY d.d_date_sk
),
sales_comparison AS (
    SELECT 
        d.d_date_sk,
        COALESCE(c.total_sales, 0) AS current_year_sales,
        COALESCE(p.total_sales_prev, 0) AS previous_year_sales,
        COALESCE(c.order_count, 0) AS current_year_order_count,
        COALESCE(p.order_count_prev, 0) AS previous_year_order_count,
        COALESCE(c.avg_order_value, 0) AS current_avg_order_value,
        COALESCE(p.avg_order_value_prev, 0) AS previous_avg_order_value
    FROM date_dim d
    LEFT JOIN current_year_sales c ON d.d_date_sk = c.sold_date_sk
    LEFT JOIN previous_year_sales p ON d.d_date_sk = p.d_date_sk
    WHERE d.d_year IN (EXTRACT(YEAR FROM CURRENT_DATE), EXTRACT(YEAR FROM CURRENT_DATE) - 1)
)
SELECT 
    s.s_store_name,
    s.s_country,
    sc.d_date_sk,
    sc.current_year_sales,
    sc.previous_year_sales,
    sc.current_year_order_count,
    sc.previous_year_order_count,
    (sc.current_year_sales - sc.previous_year_sales) / NULLIF(sc.previous_year_sales, 0) AS sales_growth_percentage,
    RANK() OVER (PARTITION BY s.s_country ORDER BY sales_growth_percentage DESC) AS ranking
FROM sales_comparison sc
JOIN sales_hierarchy s ON 1=1
WHERE (sc.current_year_sales > sc.previous_year_sales OR (sc.current_year_sales = 0 AND sc.previous_year_sales = 0))
ORDER BY s.s_country, sales_growth_percentage DESC;
