
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year >= 1980
    GROUP BY ws.web_site_sk, ws.ws_sold_date_sk
    UNION ALL
    SELECT 
        ss.web_site_sk,
        ss.ws_sold_date_sk,
        ss.total_sales + ss.total_sales,
        ss.total_orders + 1
    FROM sales_summary ss
    JOIN web_sales ws ON ss.web_site_sk = ws.ws_web_site_sk AND ss.ws_sold_date_sk = ws.ws_sold_date_sk
    WHERE ss.total_orders < 10
), avg_sales AS (
    SELECT 
        web_site_sk,
        AVG(total_sales) AS avg_sales_per_site
    FROM sales_summary
    GROUP BY web_site_sk
), return_summary AS (
    SELECT 
        wr.wr_web_page_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk
)
SELECT 
    ws.web_site_sk,
    a.avg_sales_per_site,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_value, 0.00) AS total_return_value,
    ROUND(a.avg_sales_per_site - COALESCE(r.total_return_value, 0.00), 2) AS net_value_after_returns
FROM avg_sales a
LEFT JOIN return_summary r ON a.web_site_sk = r.wr_web_page_sk
JOIN web_site ws ON a.web_site_sk = ws.web_site_sk
WHERE a.avg_sales_per_site > 1000
ORDER BY net_value_after_returns DESC;
