
WITH RECURSIVE sales_data AS (
    SELECT ws.warehouse_sk, 
           ws_promo_sk, 
           SUM(ws.ext_sales_price) AS total_sales,
           COUNT(ws.order_number) AS total_orders,
           DENSE_RANK() OVER (PARTITION BY ws.warehouse_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN store s ON ws.warehouse_sk = s.store_sk
    GROUP BY ws.warehouse_sk, ws.ws_promo_sk
    UNION ALL
    SELECT sd.warehouse_sk, 
           sd.ws_promo_sk, 
           sd.total_sales * 1.1, -- Simulating growth
           sd.total_orders * 1.05,  -- Simulating growth
           DENSE_RANK() OVER (PARTITION BY sd.warehouse_sk ORDER BY sd.total_sales * 1.1 DESC) AS sales_rank
    FROM sales_data sd
    WHERE sd.sales_rank <= 10
),
combined_returns AS (
    SELECT wr.returning_customer_sk AS customer_sk, 
           SUM(wr.return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
    UNION
    SELECT cr.returning_customer_sk AS customer_sk, 
           SUM(cr.return_amount) AS total_return_amt
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
aggregate_data AS (
    SELECT c.c_customer_sk AS customer_sk,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(cr.total_return_amt, 0) AS total_return_amt,
           COALESCE(sd.total_sales, 0) - COALESCE(cr.total_return_amt, 0) AS net_sales
    FROM customer c
    LEFT JOIN sales_data sd ON c.c_customer_sk = sd.warehouse_sk
    LEFT JOIN combined_returns cr ON c.c_customer_sk = cr.customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 2000
)
SELECT ad.customer_sk,
       ad.total_sales,
       ad.total_return_amt,
       ad.net_sales,
       CASE 
           WHEN ad.net_sales > 1000 THEN 'High Value Customer'
           WHEN ad.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value_segment
FROM aggregate_data ad
WHERE ad.total_sales IS NOT NULL
ORDER BY ad.net_sales DESC
LIMIT 50;
