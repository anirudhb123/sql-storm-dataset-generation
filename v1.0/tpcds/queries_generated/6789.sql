
WITH RankedSales AS (
    SELECT ws.web_site_id, 
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id
),
TopSales AS (
    SELECT web_site_id, total_sales
    FROM RankedSales
    WHERE sales_rank <= 10
)
SELECT ts.web_site_id, 
       ts.total_sales,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       AVG(ws.ws_sales_price) AS avg_order_value,
       SUM(ws.ws_ext_discount_amt) AS total_discount
FROM TopSales ts
JOIN web_sales ws ON ts.web_site_id = ws.ws_web_site_sk
GROUP BY ts.web_site_id, ts.total_sales
ORDER BY ts.total_sales DESC;
