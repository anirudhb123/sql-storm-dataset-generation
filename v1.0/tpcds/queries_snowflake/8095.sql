
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_web_sales, 
           SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesComparisons AS (
    SELECT cs.c_customer_sk, 
           cs.c_first_name, 
           cs.c_last_name, 
           cs.total_web_sales,
           cs.total_store_sales,
           CASE 
               WHEN cs.total_web_sales > cs.total_store_sales THEN 'Web'
               WHEN cs.total_web_sales < cs.total_store_sales THEN 'Store'
               ELSE 'Equal'
           END AS preferred_channel
    FROM CustomerSales cs
)

SELECT sc.c_first_name,
       sc.c_last_name,
       sc.total_web_sales,
       sc.total_store_sales,
       sc.preferred_channel,
       d.d_year,
       d.d_month_seq,
       MAX(ic.inv_quantity_on_hand) AS max_inventory_on_hand
FROM SalesComparisons sc
JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(ws.ws_sold_date_sk) 
    FROM web_sales ws 
    WHERE ws.ws_bill_customer_sk = sc.c_customer_sk
)
LEFT JOIN inventory ic ON ic.inv_item_sk = (
    SELECT ws.ws_item_sk 
    FROM web_sales ws 
    WHERE ws.ws_bill_customer_sk = sc.c_customer_sk 
    ORDER BY ws.ws_sold_date_sk DESC 
    LIMIT 1
)
GROUP BY sc.c_first_name, sc.c_last_name, sc.total_web_sales, sc.total_store_sales, sc.preferred_channel, d.d_year, d.d_month_seq, sc.c_customer_sk
ORDER BY sc.total_web_sales DESC, sc.total_store_sales DESC
LIMIT 100;
