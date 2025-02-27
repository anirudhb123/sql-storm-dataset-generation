
WITH RECURSIVE SalesCTE AS (
    SELECT ws.bill_customer_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (
        SELECT MIN(d_date_sk)
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ws.bill_customer_sk
),
TopCustomerSales AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           s.total_sales
    FROM customer c
    JOIN SalesCTE s ON c.c_customer_sk = s.bill_customer_sk
    WHERE s.sales_rank <= 10
)
SELECT DISTINCT 
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       COALESCE(s.total_sales, 0) AS total_sales,
       CASE 
           WHEN s.total_sales IS NOT NULL THEN 'Top Customer'
           ELSE 'Regular Customer'
       END AS customer_type,
       c.c_email_address,
       CASE 
           WHEN c.c_birth_month = 12 THEN 'Holiday Season'
           ELSE 'Regular Month'
       END AS special_month
FROM customer c
LEFT JOIN TopCustomerSales s ON c.c_customer_id = s.c_customer_id
WHERE c.c_preferred_cust_flag = 'Y'
  AND (c.c_birth_year % 2 = 0 OR c.c_birth_day IS NULL)
ORDER BY total_sales DESC, c.c_last_name ASC;

WITH ItemSales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT i.i_item_id,
       i.i_product_name,
       is.total_quantity,
       is.avg_sales_price,
       CASE 
           WHEN is.total_quantity > 100 THEN 'Best Seller'
           WHEN is.total_quantity BETWEEN 50 AND 100 THEN 'Moderate Seller'
           ELSE 'Poor Seller'
       END AS sales_category
FROM item i
JOIN ItemSales is ON i.i_item_sk = is.ws_item_sk
WHERE i.i_current_price IS NOT NULL
  AND i.i_rec_start_date <= CURRENT_DATE
  AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE);
