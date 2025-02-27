
WITH RecursiveCustomerTotals AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COALESCE(SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0), 0) AS avg_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT c.c_customer_sk,
           ct.total_orders,
           ct.total_sales,
           ct.avg_order_value,
           cd.cd_gender,
           cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ct.total_sales DESC) AS gender_rank
    FROM RecursiveCustomerTotals ct
    JOIN customer_demographics cd ON ct.c_customer_sk = cd.cd_demo_sk
    WHERE ct.total_sales > (SELECT AVG(ct2.total_sales) FROM RecursiveCustomerTotals ct2)
),
TopWebSiteSales AS (
    SELECT ws.ws_web_site_sk,
           SUM(ws.ws_ext_sales_price) AS site_sales
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk
),
WebReturnsData AS (
    SELECT wr.wr_web_page_sk,
           SUM(wr.wr_return_amt_inc_tax) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk
),
SalesComparison AS (
    SELECT w.ws_web_site_sk,
           ws.site_sales,
           COALESCE(wr.total_returns, 0) AS total_returns,
           (ws.site_sales - COALESCE(wr.total_returns, 0)) AS net_sales
    FROM TopWebSiteSales ws
    LEFT JOIN WebReturnsData wr ON ws.ws_web_site_sk = wr.wr_web_page_sk
)
SELECT hvc.c_customer_sk,
       hvc.total_orders,
       hvc.total_sales,
       hvc.avg_order_value,
       wc.web_site_id,
       sc.site_sales,
       sc.total_returns,
       sc.net_sales,
       CASE 
           WHEN sc.net_sales > 0 THEN 'Positive'
           WHEN sc.net_sales = 0 THEN 'Neutral'
           ELSE 'Negative'
       END AS sales_status
FROM HighValueCustomers hvc
JOIN SalesComparison sc ON hvc.total_sales = sc.site_sales
JOIN web_site wc ON sc.ws_web_site_sk = wc.web_site_sk
WHERE hvc.gender_rank <= 10
ORDER BY hvc.total_sales DESC, wc.web_site_id ASC;
