
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_street_name,
        ca.ca_street_type,
        ca.ca_street_number,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS address_length
    FROM customer_address ca
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS count_by_marital_status,
        STRING_AGG(cd.cd_education_status, ', ') AS education_statuses
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        STRING_AGG(DISTINCT sm.sm_type, ', ') AS ship_modes_used
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY d.d_date
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.full_address,
    ad.address_length,
    de.cd_gender,
    de.count_by_marital_status,
    de.education_statuses,
    ds.d_date,
    ds.total_sales,
    ds.ship_modes_used
FROM AddressDetails ad
JOIN Demographics de ON de.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = ad.ca_address_sk LIMIT 1)
JOIN DailySales ds ON ds.d_date = (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = (SELECT MAX(d_date_sk) FROM web_sales) LIMIT 1)
ORDER BY ad.ca_city, ds.d_date DESC
LIMIT 100;
