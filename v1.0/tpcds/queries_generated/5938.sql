
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_net_sales) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_sales) DESC) AS sales_rank
    FROM web_sales AS ws
    JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year >= 2021
    GROUP BY ws.web_site_id, d.d_year
),
TopSales AS (
    SELECT 
        year,
        web_site_id,
        total_sales,
        order_count
    FROM (
        SELECT 
            d_year AS year, 
            web_site_id, 
            total_sales, 
            order_count,
            RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS rank
        FROM RankedSales
    ) AS Ranked
    WHERE rank <= 5
)
SELECT 
    ts.year,
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    ca.city AS location,
    sm.sm_type AS shipping_method
FROM TopSales AS ts
JOIN customer_address AS ca ON ca.ca_address_id = ts.web_site_id -- Assuming web_site_id corresponds to address_id for demonstration
JOIN ship_mode AS sm ON sm.sm_ship_mode_sk = (SELECT TOP 1 sm_ship_mode_sk FROM web_sales WHERE ws_web_site_sk = (SELECT web_site_sk FROM web_site WHERE web_site_id = ts.web_site_id) ORDER BY ws_sold_date_sk DESC)
ORDER BY ts.year, ts.total_sales DESC;
