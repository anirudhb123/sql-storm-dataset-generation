
WITH RepeatedReturns AS (
    SELECT wr_returning_customer_sk, 
           COUNT(*) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    HAVING COUNT(*) > 1
),
SalesStats AS (
    SELECT ws.web_site_sk,
           SUM(ws.ws_net_paid_inc_tax) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY ws.web_site_sk
),
TopWebsites AS (
    SELECT w.w_warehouse_id, 
           ss.total_sales,
           ss.order_count,
           CASE 
               WHEN ss.total_sales IS NULL THEN 'No Sales'
               ELSE 'Sales Recorded'
           END AS sales_status
    FROM warehouse w
    LEFT JOIN SalesStats ss ON w.w_warehouse_sk = ss.web_site_sk
    WHERE w.w_country = 'USA'
)
SELECT tw.w_warehouse_id,
       COALESCE(tw.total_sales, 0) AS total_sales,
       tw.order_count,
       rp.return_count,
       CASE 
           WHEN rp.return_count IS NOT NULL THEN 'Customer returns found'
           ELSE 'No returns by this customer'
       END AS returns_status
FROM TopWebsites tw
LEFT JOIN RepeatedReturns rp ON tw.w_warehouse_id = rp.w_returning_customer_sk
WHERE tw.total_sales > (SELECT AVG(total_sales) FROM SalesStats)
ORDER BY total_sales DESC, tw.w_warehouse_id;
