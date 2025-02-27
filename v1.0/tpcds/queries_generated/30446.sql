
WITH RECURSIVE AddressTree AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country, at.level + 1
    FROM customer_address ca
    JOIN AddressTree at ON ca.ca_state = at.ca_state AND ca.ca_city != at.ca_city
),
SalesData AS (
    SELECT ws.web_site_sk, ws.ws_order_number, ws.ws_sales_price, ws.ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) as rn
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 2000
      AND c.c_preferred_cust_flag = 'Y'
),
TotalSales AS (
    SELECT web_site_sk, SUM(ws_sales_price) as total_sales
    FROM SalesData
    GROUP BY web_site_sk
),
RankedSales AS (
    SELECT ts.web_site_sk, ts.total_sales,
           RANK() OVER (ORDER BY ts.total_sales DESC) as sales_rank
    FROM TotalSales ts
),
FilteredRank AS (
    SELECT r.web_site_sk, r.total_sales
    FROM RankedSales r
    WHERE r.sales_rank <= 10
)
SELECT 
    at.ca_city,
    at.ca_state,
    at.ca_country,
    fr.total_sales,
    COALESCE(SUM(sd.ws_net_profit), 0) AS total_net_profit,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders
FROM AddressTree at
LEFT JOIN FilteredRank fr ON fr.web_site_sk = at.ca_address_sk
LEFT JOIN SalesData sd ON fr.web_site_sk = sd.web_site_sk
GROUP BY at.ca_city, at.ca_state, at.ca_country, fr.total_sales
ORDER BY at.ca_city, total_sales DESC;
