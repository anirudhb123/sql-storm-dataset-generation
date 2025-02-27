
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer_address ca
),
TopCustomers AS (
    SELECT
        ch.c_customer_sk,
        CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS customer_name,
        ad.full_address,
        SUM(sd.total_sales) AS total_sales
    FROM CustomerHierarchy ch
    JOIN AddressDetails ad ON ch.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON DATE(sd.ws_sold_date_sk) = CURRENT_DATE
    GROUP BY ch.c_customer_sk, customer_name, ad.full_address
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT 
    tc.customer_name,
    tc.full_address,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.total_quantity, 0) AS total_quantity,
    COALESCE(t.avg_net_profit, 0) AS avg_net_profit
FROM TopCustomers tc
LEFT JOIN SalesData t ON t.ws_sold_date_sk = CURRENT_DATE
FULL OUTER JOIN web_returns wr ON wr.wr_returning_customer_sk = tc.c_customer_sk
WHERE wr.wr_returned_date_sk IS NULL
ORDER BY tc.total_sales DESC, tc.customer_name;
