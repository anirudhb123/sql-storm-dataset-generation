
WITH cumulative_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.web_site_sk
), 
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(total_orders) AS avg_orders
    FROM cumulative_sales
), 
site_sales AS (
    SELECT 
        c.c_customer_id,
        d.d_date,
        cs.total_sales,
        cs.total_orders,
        CASE WHEN cs.total_sales > (SELECT avg_sales FROM average_sales) THEN 'Above Average' ELSE 'Below Average' END AS sales_performance
    FROM cumulative_sales cs
    JOIN web_sales ws ON cs.web_site_sk = ws.ws_web_site_sk
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
)
SELECT 
    s.site_sales_id,
    s.sales_performance,
    CONCAT('Total Sales: ', CAST(s.total_sales AS VARCHAR), ' | Total Orders: ', CAST(s.total_orders AS VARCHAR)) AS sales_summary,
    CASE 
        WHEN s.sales_performance = 'Above Average' AND s.total_orders > (SELECT MAX(total_orders) FROM cumulative_sales) * 0.75 THEN 'High Engagement'
        ELSE 'Regular Engagement' 
    END AS engagement_level,
    COALESCE(NULLIF(s.total_sales, 0), 'No Sales Recorded') AS adjusted_sales
FROM site_sales s
FULL OUTER JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = s.c_customer_id LIMIT 1)
WHERE cd.cd_gender IS NOT NULL
      AND (s.total_orders > 0 OR s.total_sales > (SELECT AVG(total_sales) FROM cumulative_sales WHERE total_orders > 5))
ORDER BY s.sales_performance DESC, s.total_sales DESC
LIMIT 100;
