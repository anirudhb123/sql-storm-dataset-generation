
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS FullAddress,
        LENGTH(ca_street_number) AS StreetNumberLength,
        LENGTH(ca_street_name) AS StreetNameLength,
        COUNT(DISTINCT ca_city) OVER() AS TotalDistinctCities
    FROM customer_address
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount,
        AVG(ws_quantity) AS AvgQuantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
DemographicsInfo AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS CustomerCount
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
)
SELECT
    ai.FullAddress,
    ss.TotalSales,
    ss.OrderCount,
    ss.AvgQuantity,
    di.CustomerCount,
    di.cd_gender,
    di.cd_marital_status,
    ai.TotalDistinctCities
FROM AddressInfo ai
JOIN SalesSummary ss ON ss.ws_bill_customer_sk = ai.ca_address_sk
JOIN DemographicsInfo di ON di.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = ss.ws_bill_customer_sk)
WHERE ai.StreetNameLength > 5
  AND di.cd_marital_status = 'M'
ORDER BY ss.TotalSales DESC, ai.FullAddress;
