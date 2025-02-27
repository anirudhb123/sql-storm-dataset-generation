
WITH RECURSIVE Sales_Data AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
Avg_Sales AS (
    SELECT 
        d.d_year,
        AVG(total_sales) AS avg_daily_sales
    FROM Sales_Data sd
    JOIN date_dim d ON d.d_date_sk = sd.ws_sold_date_sk
    GROUP BY d.d_year
),
Top_Years AS (
    SELECT 
        d_year,
        ROW_NUMBER() OVER (ORDER BY avg_daily_sales DESC) AS year_rank
    FROM Avg_Sales
    WHERE avg_daily_sales > (
        SELECT AVG(avg_daily_sales) FROM Avg_Sales
    )
)
SELECT 
    t.d_year,
    COALESCE(SUM(ss_ext_sales_price), 0) AS store_sales,
    COALESCE(SUM(cs_ext_sales_price), 0) AS catalog_sales,
    COALESCE(SUM(ws_ext_sales_price), 0) AS web_sales
FROM Top_Years ty
LEFT JOIN store_sales ss ON ss.ss_sold_date_sk IN (SELECT ws_sold_date_sk FROM Sales_Data WHERE rank <= 10)
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk IN (SELECT ws_sold_date_sk FROM Sales_Data WHERE rank <= 10)
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk IN (SELECT ws_sold_date_sk FROM Sales_Data WHERE rank <= 10)
JOIN date_dim t ON t.d_year = ty.d_year
GROUP BY t.d_year
ORDER BY t.d_year DESC;
