
WITH RECURSIVE StoreHierarchy AS (
    SELECT s_store_sk, s_store_name, s_manager, s_company_id, s_division_id, 1 AS level
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, s.s_manager, s.company_id, s.division_id, sh.level + 1
    FROM store s
    JOIN StoreHierarchy sh ON s.s_manager = sh.s_store_name
),
SalesData AS (
    SELECT ws.ws_item_sk,
           ws.ws_sold_date_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
),
HighValueSales AS (
    SELECT item.i_item_id, item.i_product_name, sd.total_quantity, sd.total_sales
    FROM SalesData sd
    JOIN item ON sd.ws_item_sk = item.i_item_sk
    WHERE sd.rank <= 10
),
AddressInfo AS (
    SELECT ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_zip
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_country IS NOT NULL
),
TopStores AS (
    SELECT s.s_store_name, COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_name
    HAVING COUNT(DISTINCT ws_order_number) > 100
),
FinalResults AS (
    SELECT hs.i_product_name, hs.total_quantity, hs.total_sales, 
           ai.ca_city, ai.ca_state, ai.ca_zip,
           ts.order_count
    FROM HighValueSales hs
    JOIN AddressInfo ai ON hs.total_quantity > 50
    LEFT JOIN TopStores ts ON ai.ca_city = ts.s_store_name
)
SELECT f.*, 
       CASE WHEN f.order_count IS NULL THEN 'No Orders' ELSE 'Orders Found' END AS order_status
FROM FinalResults f
ORDER BY f.total_sales DESC
LIMIT 100;
