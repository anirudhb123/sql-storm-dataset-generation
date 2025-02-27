
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, 0 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_customer_id, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_cdemo_sk
),
DateRanks AS (
    SELECT d.d_date, 
           DENSE_RANK() OVER (ORDER BY d.d_date) AS date_rank
    FROM date_dim d
    WHERE d.d_date >= DATE '2020-01-01'
),
SalesSummary AS (
    SELECT coalesce(ws.ws_bill_cdemo_sk, cs.cs_bill_cdemo_sk, ss.ss_cdemo_sk) AS customer_id,
           SUM(COALESCE(ws.ws_net_paid, cs.cs_net_paid, ss.ss_net_paid)) AS total_sales,
           COUNT(DISTINCT COALESCE(ws.ws_order_number, cs.cs_order_number, ss.ss_ticket_number)) AS order_count
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_bill_cdemo_sk = cs.cs_bill_cdemo_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_bill_cdemo_sk = ss.ss_cdemo_sk
    GROUP BY customer_id
),
TopCustomers AS (
    SELECT c.c_customer_id,
           s.total_sales,
           s.order_count,
           ROW_NUMBER() OVER (PARTITION BY NULL ORDER BY s.total_sales DESC) AS rank
    FROM SalesSummary s
    JOIN customer c ON c.c_customer_sk = s.customer_id
    WHERE s.total_sales > 0
)
SELECT a.ca_city, 
       SUM(sc.total_sales) AS total_city_sales,
       COUNT(DISTINCT tc.c_customer_id) AS total_customers,
       MAX(d.date_rank) AS latest_order_rank
FROM TopCustomers tc
JOIN CustomerHierarchy ch ON tc.c_customer_id = ch.c_customer_id
JOIN store s ON ch.c_customer_sk = s.s_store_sk
JOIN customer_address a ON s.s_closed_date_sk = a.ca_address_sk
JOIN DateRanks d ON d.d_date = CURRENT_DATE
LEFT JOIN SalesSummary sc ON sc.customer_id = ch.c_customer_sk
GROUP BY a.ca_city
HAVING COUNT(DISTINCT tc.c_customer_id) > 5
ORDER BY total_city_sales DESC;
