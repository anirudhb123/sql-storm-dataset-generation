
WITH CustomerCity AS (
    SELECT ca_city, COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address
    JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY ca_city
),
CityDemographics AS (
    SELECT cd_gender, cd_marital_status, COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
SalesByGender AS (
    SELECT cd.cd_gender, SUM(ws.ws_net_sales) AS total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
CitySales AS (
    SELECT ca.ca_city, SUM(ws.ws_net_sales) AS total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
),
FinalBenchmark AS (
    SELECT cc.ca_city, 
           cc.customer_count, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.demographic_count, 
           sbg.total_sales AS sales_by_gender, 
           cs.total_sales AS sales_by_city
    FROM CustomerCity cc
    CROSS JOIN CityDemographics cd
    LEFT JOIN SalesByGender sbg ON cd.cd_gender = sbg.cd_gender
    LEFT JOIN CitySales cs ON cc.ca_city = cs.ca_city
)

SELECT 
    ca_city, 
    customer_count, 
    cd_gender, 
    cd_marital_status, 
    demographic_count, 
    COALESCE(sales_by_gender, 0) AS sales_by_gender, 
    COALESCE(sales_by_city, 0) AS sales_by_city
FROM FinalBenchmark
ORDER BY ca_city, cd_gender, cd_marital_status;
