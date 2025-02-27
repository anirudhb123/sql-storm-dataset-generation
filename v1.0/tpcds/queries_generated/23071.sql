
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_customer_id, 
           SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
           COUNT(DISTINCT COALESCE(ss.ss_ticket_number, ws.ws_order_number)) AS total_orders
    FROM customer AS c
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
Demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           COUNT(c.c_customer_sk) AS customer_count
    FROM customer_demographics AS cd
    LEFT JOIN customer AS c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesPerformance AS (
    SELECT cs.c_customer_sk,
           cs.total_sales,
           cs.total_orders,
           CASE
               WHEN cs.total_orders > 0 THEN cs.total_sales / cs.total_orders
               ELSE NULL
           END AS avg_sales_per_order,
           CASE
               WHEN d.customer_count > 0 THEN cs.total_sales / d.customer_count
               ELSE NULL
           END AS sales_per_demographics
    FROM CustomerSales AS cs
    JOIN Demographics AS d ON d.cd_demo_sk = (
        SELECT hd.hd_demo_sk 
        FROM household_demographics AS hd 
        WHERE hd.hd_dep_count IS NOT NULL 
          AND hd.hd_income_band_sk IS NOT NULL
        ORDER BY RANDOM()
        LIMIT 1
    )
)
SELECT sp.c_customer_sk, 
       COALESCE(sp.total_sales, 0) AS total_sales, 
       COALESCE(sp.avg_sales_per_order, 0) AS avg_sales_per_order, 
       COALESCE(sp.sales_per_demographics, 0) AS sales_per_demographics,
       CASE 
           WHEN COALESCE(sp.total_sales, 0) > 1000 THEN 'High Value'
           WHEN COALESCE(sp.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value
FROM SalesPerformance AS sp
ORDER BY customer_value DESC, total_sales DESC
FETCH FIRST 50 ROWS ONLY;
