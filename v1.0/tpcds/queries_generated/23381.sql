
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_county, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_county, a.ca_state, c.level + 1
    FROM customer_address a
    JOIN AddressCTE c ON a.ca_county = c.ca_county AND a.ca_state = c.ca_state
    WHERE c.level < 2
),
DemographicsCTE AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS demo_rank
    FROM customer_demographics
),
SalesTotals AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT st.ws_item_sk, st.total_sales, st.order_count,
           ROW_NUMBER() OVER (PARTITION BY st.ws_item_sk ORDER BY st.total_sales DESC) AS item_rank
    FROM SalesTotals st
    WHERE st.order_count > 5 
      AND st.total_sales > (SELECT AVG(total_sales) FROM SalesTotals)
),
FinalReport AS (
    SELECT ca.city,
           SUM(CASE WHEN cd.cd_marital_status = 'M' THEN st.total_sales ELSE 0 END) AS married_sales,
           SUM(CASE WHEN cd.cd_gender = 'F' THEN st.total_sales ELSE 0 END) AS female_sales,
           COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM customer c
    JOIN AddressCTE ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN DemographicsCTE cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN FilteredSales st ON c.c_customer_sk = st.ws_item_sk
    WHERE cd.marital_status IS NOT NULL
      AND ca.ca_city IS NOT NULL
    GROUP BY ca.city
)
SELECT f.city, f.married_sales, f.female_sales, COALESCE(f.unique_customers, 0) AS unique_customers,
       CASE 
           WHEN f.unique_customers = 0 THEN 'No customers'
           WHEN f.married_sales > f.female_sales THEN 'Married dominant'
           ELSE 'Female dominant'
       END AS dominance_type
FROM FinalReport f
WHERE EXISTS (SELECT 1 FROM store WHERE s_store_sk = (SELECT s_store_sk FROM store_sales WHERE ss_item_sk = (SELECT MIN(ws_item_sk) FROM web_sales)))
  AND (f.married_sales IS NOT NULL OR f.female_sales IS NOT NULL)
ORDER BY dominance_type DESC, married_sales DESC;
