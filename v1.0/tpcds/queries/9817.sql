
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name,
           SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
           COUNT(DISTINCT COALESCE(ws.ws_order_number, cs.cs_order_number, ss.ss_ticket_number)) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_sales,
           cs.total_orders,
           DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > 0
)
SELECT tc.c_customer_sk, 
       tc.c_first_name, 
       tc.c_last_name, 
       tc.total_sales, 
       tc.total_orders, 
       tc.sales_rank,
       ca.ca_city, 
       ca.ca_state, 
       ca.ca_country
FROM TopCustomers tc
JOIN customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
