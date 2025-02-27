
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_street_name, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    INNER JOIN AddressHierarchy ah ON ca.ca_city = ah.ca_city AND ca.ca_state = ah.ca_state
    WHERE ah.level < 5
),
CustomerSales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_ext_sales_price) AS total_sales, 
           COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
SalesSummary AS (
    SELECT cs.c_customer_sk, 
           CAST(CASE WHEN cs.order_count = 0 THEN NULL ELSE cs.total_sales / cs.order_count END AS decimal(10,2)) AS avg_order_value,
           cd.cd_gender,
           cd.cd_marital_status,
           ad.ca_city
    FROM CustomerSales cs
    LEFT JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
),
HighValueCustomers AS (
    SELECT s.*, ROW_NUMBER() OVER (PARTITION BY s.cd_gender ORDER BY s.avg_order_value DESC) AS rank
    FROM SalesSummary s
    WHERE s.avg_order_value IS NOT NULL AND s.avg_order_value > 1000
)
SELECT hv.*, 
       COALESCE(NULLIF(ah.ca_street_name, ''), 'Unknown') AS street_name,
       CASE 
           WHEN hv.cd_marital_status = 'M' THEN 'Married'
           WHEN hv.cd_marital_status = 'S' THEN 'Single'
           ELSE 'Other'
       END AS marital_status_desc
FROM HighValueCustomers hv
LEFT JOIN AddressHierarchy ah ON hv.ca_city = ah.ca_city
WHERE hv.rank <= 10
ORDER BY hv.cd_gender, hv.avg_order_value DESC;
