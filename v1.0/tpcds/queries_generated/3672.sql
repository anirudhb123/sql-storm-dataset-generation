
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_year
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer_address ca
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_birth_year,
    ad.full_address,
    rs.total_sales
FROM CustomerDetails cd
LEFT JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN RankedSales rs ON cd.c_customer_sk = rs.ws_item_sk
WHERE cd.cd_gender = 'M' 
    AND cd.cd_birth_year > 1980
    AND (ad.full_address IS NOT NULL OR cd.cd_marital_status = 'S')
ORDER BY rs.total_sales DESC
LIMIT 10;

-- This query combines correlated subqueries and CTEs to extract valuable insights by aggregating sales data 
-- and correlating it with customer and address details, highlighting potential sales performance ranking by demographics.
