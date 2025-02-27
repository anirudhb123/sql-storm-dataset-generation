
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20140101 AND 20141231
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.*, 
           ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM CustomerSales c
)
SELECT tc.c_first_name, 
       tc.c_last_name, 
       tc.total_sales, 
       CASE 
           WHEN cd.cd_gender = 'M' THEN 'Male'
           WHEN cd.cd_gender = 'F' THEN 'Female'
           ELSE 'Unknown'
       END AS gender,
       cd.cd_marital_status,
       cd.cd_education_status,
       ca.ca_city,
       ca.ca_state
FROM TopCustomers tc
JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE tc.rank <= 10
ORDER BY tc.total_sales DESC
