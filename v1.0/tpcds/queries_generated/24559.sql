
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, 
           CONCAT(a.ca_street_name, ' -> ', ah.ca_street_name),
           a.ca_city,
           a.ca_state
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
    WHERE ah.ca_address_sk != a.ca_address_sk
),
CustomerDemographics AS (
    SELECT cd_gender, cd_marital_status, COUNT(*) AS demo_count
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
    GROUP BY cd_gender, cd_marital_status
),
ItemStatistics AS (
    SELECT i_brand, 
           AVG(i_current_price) AS avg_price, 
           MIN(i_current_price) AS min_price, 
           MAX(i_current_price) AS max_price
    FROM item
    WHERE i_rec_end_date >= CURRENT_DATE
    GROUP BY i_brand
),
SalesData AS (
    SELECT ws_sold_date_sk, 
           ws_quantity, 
           ws_ext_sales_price,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE))
),
AggregatedSales AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_ext_sales_price) AS total_sales
    FROM SalesData
    WHERE rn <= 5
    GROUP BY ws_bill_customer_sk
)
SELECT ah.ca_city, 
       ah.ca_state, 
       cd.demo_count, 
       it.avg_price, 
       COALESCE(asales.total_quantity, 0) AS recent_quantity,
       COALESCE(asales.total_sales, 0.00) AS recent_sales
FROM AddressHierarchy ah
LEFT JOIN CustomerDemographics cd ON cd.demo_count > 0
LEFT JOIN ItemStatistics it ON it.avg_price < (SELECT AVG(avg_price) FROM ItemStatistics)
LEFT JOIN AggregatedSales asales ON asales.ws_bill_customer_sk = cd.cd_demo_sk
WHERE ah.ca_city LIKE '%land%'
AND ah.ca_state IN ('CA', 'TX')
ORDER BY ah.ca_city DESC, recent_sales DESC;
