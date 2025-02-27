
WITH RECURSIVE SalesCTE AS (
    SELECT w.wh_warehouse_sk, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY w.wh_warehouse_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE ws_sold_date_sk IN (SELECT d_date_sk
                               FROM date_dim
                               WHERE d_year = 2023)
    GROUP BY w.wh_warehouse_sk
),
CustomerSales AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT ws.ws_order_number) AS orders_count,
           SUM(ws.ws_net_paid) AS total_spent,
           c.c_birth_year,
           CASE 
               WHEN c.c_birth_year IS NOT NULL 
                    THEN EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year
               ELSE NULL 
           END AS age
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_birth_year
),
RankedCustomers AS (
    SELECT c.customer_sk,
           c.c_first_name,
           c.c_last_name,
           cs.orders_count,
           cs.total_spent,
           DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM CustomerSales cs
    JOIN customer c ON c.c_customer_sk = cs.c_customer_sk
)
SELECT r.c_first_name, 
       r.c_last_name, 
       r.total_spent, 
       r.customer_rank, 
       s.total_sales, 
       s.total_orders
FROM RankedCustomers r
JOIN SalesCTE s ON r.customer_rank <= 10
ORDER BY s.total_sales DESC, r.total_spent DESC
LIMIT 100
```
