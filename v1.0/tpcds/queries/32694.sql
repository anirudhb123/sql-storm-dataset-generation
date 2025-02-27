
WITH RECURSIVE SalesData AS (
    SELECT ws_order_number, 
           ws_item_sk, 
           ws_quantity, 
           ws_net_paid, 
           ws_sales_price, 
           1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT ws.ws_order_number, 
           ws.ws_item_sk, 
           ws.ws_quantity, 
           ws.ws_net_paid, 
           ws.ws_sales_price, 
           sd.level + 1
    FROM web_sales ws
    JOIN SalesData sd ON ws.ws_order_number = sd.ws_order_number 
                      AND ws.ws_item_sk <> sd.ws_item_sk
    WHERE sd.level < 5
), AvgSales AS (
    SELECT ws_item_sk,
           AVG(ws_net_paid) AS avg_net_paid,
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    WHERE ws_sales_price > 100
    GROUP BY ws_item_sk
), HighValueCustomers AS (
    SELECT c.c_customer_id,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year < 1980
    GROUP BY c.c_customer_id
    HAVING COUNT(DISTINCT ws.ws_order_number) > 10
)
SELECT DISTINCT ca.ca_city,
                SUM(ws.ws_net_paid) AS total_sales,
                COUNT(DISTINCT hc.c_customer_id) AS high_value_customers,
                AVG(a.avg_net_paid) AS avg_item_net_paid
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
INNER JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN HighValueCustomers hc ON c.c_customer_id = hc.c_customer_id
LEFT JOIN AvgSales a ON ws.ws_item_sk = a.ws_item_sk
WHERE ca.ca_state = 'CA'
  AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY ca.ca_city
HAVING SUM(ws.ws_net_paid) > 100000
ORDER BY total_sales DESC, avg_item_net_paid DESC;
