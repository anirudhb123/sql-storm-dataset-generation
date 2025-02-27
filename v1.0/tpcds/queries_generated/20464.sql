
WITH RECURSIVE CustomerHierachy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           CAST(c.c_first_name AS VARCHAR(50)) AS full_name,
           0 AS level
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL
  
    UNION ALL
  
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.full_name || ' -> ' || c.c_first_name,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierachy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 10
), 
AddressDetails AS (
    SELECT ca.*, 
           COALESCE(NULLIF(ca.ca_city, ''), 'Unknown City') AS city_or_unknown,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM customer_address ca
    WHERE ca.ca_state IN ('NY', 'CA') OR (ca.ca_gmt_offset >= 0 AND ca.ca_zip LIKE '9%')
), 
CustomerWithAddresses AS (
    SELECT ch.c_customer_sk, ch.full_name, ad.full_address,
           ROW_NUMBER() OVER (PARTITION BY ch.c_customer_sk ORDER BY ad.ca_zip DESC) AS rn
    FROM CustomerHierachy ch
    LEFT JOIN AddressDetails ad ON ch.c_current_addr_sk = ad.ca_address_sk
)
SELECT cwa.c_customer_sk, cwa.full_name, cwa.full_address, ca.ca_country,
       SUM(COALESCE(ws.ws_quantity, 0)) AS total_web_sales_quantity,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       COUNT(DISTINCT cr.cr_order_number) FILTER (WHERE cr.cr_return_quantity > 0) AS total_returns,
       CASE 
           WHEN SUM(ws.ws_sales_price) IS NULL THEN 'No Sales'
           ELSE CAST(SUM(ws.ws_sales_price) AS VARCHAR)
       END AS total_sales_amount,
       CASE 
           WHEN SUM(CASE WHEN ws.ws_net_profit IS NULL THEN 0 ELSE ws.ws_net_profit END) > 1000 THEN 'High Profit'
           ELSE 'Normal Profit'
       END AS profit_category
FROM CustomerWithAddresses cwa
LEFT JOIN web_sales ws ON cwa.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_returns cr ON cwa.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN customer_address ca ON cwa.full_address LIKE '%' || ca.ca_city || '%'
WHERE cwa.rn = 1 AND 
      (cwa.full_name LIKE '%John%' OR cwa.full_name LIKE '%Doe%') 
GROUP BY cwa.c_customer_sk, cwa.full_name, cwa.full_address, ca.ca_country
ORDER BY total_web_sales_quantity DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
