
WITH RECURSIVE SalesCTE AS (
    SELECT ss_item_sk,
           ss_net_paid,
           ss_sold_date_sk,
           1 AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk = (
        SELECT MAX(ss_sold_date_sk)
        FROM store_sales
    )
    UNION ALL
    SELECT ss.ss_item_sk,
           ss.ss_net_paid,
           ss.ss_sold_date_sk,
           sc.sales_rank + 1
    FROM store_sales ss
    JOIN SalesCTE sc ON ss.ss_item_sk = sc.ss_item_sk
    WHERE sc.sales_rank < 5
), 
CustomerSales AS (
    SELECT c.c_customer_sk, 
           SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
), 
MaxCustomerSales AS (
    SELECT cs.c_customer_sk, 
           cs.total_spent,
           RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSales cs
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    cs.total_spent,
    ws.ws_sales_price,
    RANK() OVER (PARTITION BY ws.ws_ship_date_sk ORDER BY cs.total_spent DESC) AS sales_rank,
    d.d_date AS sales_date,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM MaxCustomerSales cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023
  AND cs.total_spent > (
      SELECT AVG(total_spent) FROM CustomerSales
  )
ORDER BY cs.total_spent DESC;
