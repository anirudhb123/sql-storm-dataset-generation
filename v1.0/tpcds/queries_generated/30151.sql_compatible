
WITH RECURSIVE daily_sales AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_sold_date_sk
    HAVING SUM(ws_net_paid) > (
        SELECT AVG(ws_net_paid) FROM web_sales
    )
    UNION ALL
    SELECT 
        d.d_date_sk,
        COALESCE(ds.total_sales, 0) + 1,
        COALESCE(ds.order_count, 0) + 1
    FROM date_dim d
    LEFT JOIN daily_sales ds ON d.d_date_sk = ds.ws_sold_date_sk
    WHERE d.d_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
ranked_sales AS (
    SELECT 
        ds.ws_sold_date_sk,
        ds.total_sales,
        ds.order_count,
        RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
    FROM daily_sales ds
)
SELECT 
    dd.d_date,
    COALESCE(rs.total_sales, 0) AS daily_total_sales,
    COALESCE(rs.order_count, 0) AS daily_order_count,
    CASE 
        WHEN rs.sales_rank IS NOT NULL THEN 'Top Performer'
        ELSE 'Regular Day'
    END AS sales_category
FROM date_dim dd
LEFT JOIN ranked_sales rs ON dd.d_date_sk = rs.ws_sold_date_sk
WHERE dd.d_year = 2023 AND dd.d_month_seq IN (4, 5)
ORDER BY dd.d_date;
