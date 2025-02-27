
WITH RECURSIVE Sales_By_Day AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_date
    UNION ALL
    SELECT 
        d.d_date,
        SUM(cs.cs_sales_price * cs.cs_quantity) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM date_dim d
    JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_date
),
Sales_Stats AS (
    SELECT 
        s.d_date,
        s.total_sales,
        s.total_orders,
        LAG(s.total_sales) OVER (ORDER BY s.d_date) AS prev_sales,
        LEAD(s.total_sales) OVER (ORDER BY s.d_date) AS next_sales,
        CASE 
            WHEN s.total_sales > COALESCE(s.prev_sales, 0) THEN 'Increase'
            WHEN s.total_sales < COALESCE(s.prev_sales, 0) THEN 'Decrease'
            ELSE 'No Change'
        END AS sales_trend
    FROM Sales_By_Day s
),
Filtered_Sales AS (
    SELECT 
        d.d_date,
        COALESCE(s.total_sales, 0) AS total_sales,
        COUNT(DISTINCT CASE WHEN s.total_orders IS NOT NULL THEN s.total_orders END) AS order_count,
        CASE 
            WHEN SUM(s.total_sales) > 10000 THEN 'High Performer'
            WHEN SUM(s.total_sales) BETWEEN 5000 AND 10000 THEN 'Medium Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM date_dim d
    LEFT JOIN Sales_Stats s ON d.d_date = s.d_date
    GROUP BY d.d_date
    HAVING COUNT(DISTINCT s.total_orders) > 0
)
SELECT 
    f.d_date, 
    f.total_sales, 
    f.order_count, 
    f.performance_category,
    CASE 
        WHEN f.performance_category = 'High Performer' THEN 'Congratulations on your high sales!'
        WHEN f.performance_category = 'Medium Performer' AND f.order_count > 10 THEN 'You are doing great, but can improve!'
        ELSE NULL
    END AS performance_message
FROM Filtered_Sales f
WHERE f.total_sales IS NOT NULL
ORDER BY f.d_date DESC
LIMIT 30
OFFSET (SELECT COUNT(*) FROM Filtered_Sales) / 3
