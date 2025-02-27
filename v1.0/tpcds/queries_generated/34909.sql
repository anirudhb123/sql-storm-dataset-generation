
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales, COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT s.ws_item_sk, SUM(s.ws_sales_price) AS total_sales, COUNT(s.ws_order_number) AS total_orders
    FROM store_sales s
    JOIN SalesCTE on s.ss_item_sk = SalesCTE.ws_item_sk
    GROUP BY s.ws_item_sk
),
CustomerCTE AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           d.d_dow AS order_day_of_week,
           COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
           COUNT(ss.ss_ticket_number) AS order_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_dow
),
FilteredCustomers AS (
    SELECT c.*, 
           CASE 
               WHEN total_spent > (SELECT AVG(total_spent) FROM CustomerCTE) THEN 'High Spender'
               ELSE 'Low Spender'
           END AS spending_category
    FROM CustomerCTE c
    WHERE order_count > 1
)
SELECT fc.c_first_name || ' ' || fc.c_last_name AS customer_name,
       fc.spending_category,
       fc.total_spent,
       fc.order_day_of_week,
       s.total_sales,
       s.total_orders
FROM FilteredCustomers fc
LEFT JOIN SalesCTE s ON fc.c_customer_sk = s.ws_item_sk
ORDER BY fc.total_spent DESC, fc.order_day_of_week;
