
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.sold_date_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.sold_date_sk
),
hourly_sales AS (
    SELECT 
        EXTRACT(HOUR FROM t.t_time) AS sale_hour,
        SUM(ss.total_sales) AS hour_sales,
        SUM(ss.total_orders) AS hour_orders,
        RANK() OVER (ORDER BY SUM(ss.total_sales) DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        time_dim t ON ss.sold_date_sk = t.t_time_sk
    GROUP BY 
        sale_hour
),
filtered_sales AS (
    SELECT 
        hs.sale_hour,
        hs.hour_sales,
        hs.hour_orders
    FROM 
        hourly_sales hs
    WHERE 
        hs.hour_sales > (SELECT AVG(hour_sales) FROM hourly_sales)
)
SELECT 
    COALESCE(hs.sale_hour, 'All Hours') AS hour,
    COALESCE(hs.hour_sales, 0) AS total_sales,
    COALESCE(hs.hour_orders, 0) AS total_orders,
    CASE 
        WHEN hs.hour_sales IS NULL THEN 'Below Average'
        WHEN hs.hour_sales > (SELECT AVG(hour_sales) FROM hourly_sales) THEN 'Above Average'
        ELSE 'Average'
    END AS sales_category
FROM 
    filtered_sales hs
FULL OUTER JOIN 
    hourly_sales all_hours ON hs.sale_hour = all_hours.sale_hour
ORDER BY 
    COALESCE(hs.sale_hour, 'All Hours');
