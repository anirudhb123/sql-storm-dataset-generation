
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, a.ca_city, a.ca_state, ah.level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
    WHERE ah.level < 3
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(COALESCE(ws.ws_sales_price, 0)) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2022, 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
TopCustomers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cm.total_web_sales,
           cm.web_order_count,
           ah.ca_city
    FROM CustomerMetrics cm
    JOIN customer c ON cm.c_customer_sk = c.c_customer_sk
    LEFT JOIN AddressHierarchy ah ON c.c_current_addr_sk = ah.ca_address_sk
    WHERE cm.sales_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.web_order_count,
    COALESCE(ah.ca_city, 'Unknown') AS city,
    CASE 
        WHEN tc.total_web_sales IS NULL THEN 'No Sales'
        WHEN tc.total_web_sales < 1000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM TopCustomers tc
FULL OUTER JOIN AddressHierarchy ah ON tc.ca_city = ah.ca_city
WHERE ah.level = 1 OR ah.level IS NULL
ORDER BY tc.total_web_sales DESC NULLS LAST;
