
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_street_number, ca_street_name, ca_city, ca_state
    FROM customer_address
    WHERE ca_state IS NOT NULL
    
    UNION ALL
    
    SELECT c.ca_address_sk, c.ca_street_number, c.ca_street_name, c.ca_city, c.ca_state
    FROM customer_address AS c 
    JOIN AddressCTE AS a ON c.ca_address_sk = a.ca_address_sk
    WHERE c.ca_state <> a.ca_state
), 
CustomerDemographics AS (
    SELECT cd_gender, cd_marital_status, COUNT(*) AS demo_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
    HAVING COUNT(*) > 1
),
TotalSales AS (
    SELECT 
        SUM(ws_net_paid) AS total_sales,
        ws_ship_date_sk
    FROM web_sales
    GROUP BY ws_ship_date_sk
),
StoreSales AS (
    SELECT 
        SUM(ss_net_paid) AS total_store_sales,
        ss_sold_date_sk
    FROM store_sales
    GROUP BY ss_sold_date_sk
),
IncomeBands AS (
    SELECT 
        ib_income_band_sk,
        COUNT(*) AS band_count
    FROM household_demographics h
    JOIN income_band b ON h.hd_income_band_sk = b.ib_income_band_sk
    WHERE hd_buy_potential IS NOT NULL
    GROUP BY ib_income_band_sk
    HAVING COUNT(*) BETWEEN 1 AND 100
)
SELECT a.ca_city, a.ca_state,
       COALESCE(td.total_sales, 0) AS total_web_sales,
       COALESCE(ts.total_store_sales, 0) AS total_store_sales,
       cd.demo_count,
       ib.band_count
FROM AddressCTE a
LEFT JOIN TotalSales td ON a.ca_address_sk = td.ws_ship_date_sk
LEFT JOIN StoreSales ts ON a.ca_address_sk = ts.ss_sold_date_sk
JOIN CustomerDemographics cd ON 1=1
LEFT JOIN IncomeBands ib ON ib.ib_income_band_sk IS NULL
WHERE a.ca_city LIKE 'New%'
  AND (a.ca_state IN ('TX', 'CA') OR a.ca_state IS NULL)
  AND cd.demo_count > (SELECT AVG(demo_count) FROM CustomerDemographics)
GROUP BY a.ca_city, a.ca_state, td.total_sales, ts.total_store_sales, cd.demo_count, ib.band_count
ORDER BY a.ca_city, total_web_sales DESC
FETCH FIRST 10 ROWS ONLY;
