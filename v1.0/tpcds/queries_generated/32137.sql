
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
),
AggregatedSales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ws_bill_customer_sk
),
MaxSales AS (
    SELECT MAX(total_sales) AS max_sales
    FROM AggregatedSales
),
TopCustomers AS (
    SELECT customer.c_first_name, customer.c_last_name, sales.total_sales, 
           sales.order_count
    FROM AggregatedSales sales
    JOIN customer ON sales.ws_bill_customer_sk = customer.c_customer_sk
    WHERE sales.total_sales = (SELECT max_sales FROM MaxSales)
),
AddressDetails AS (
    SELECT ca.city, ca.state, ca.zip,
           COUNT(DISTINCT ch.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN CustomerHierarchy ch ON ch.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.city, ca.state, ca.zip
)
SELECT tc.c_first_name, tc.c_last_name, tc.total_sales, tc.order_count,
       ad.city, ad.state, ad.zip, ad.customer_count
FROM TopCustomers tc
JOIN AddressDetails ad ON ad.customer_count > 0
ORDER BY tc.total_sales DESC, ad.city ASC;
