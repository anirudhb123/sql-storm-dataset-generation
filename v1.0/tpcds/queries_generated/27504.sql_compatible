
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
DemographicsCount AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd.cd_dep_count) AS avg_dependencies
    FROM customer_demographics cd
    GROUP BY cd.cd_gender
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    di.avg_dependencies,
    di.gender_count,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM CustomerInfo ci
JOIN DemographicsCount di ON ci.cd_gender = di.cd_gender
LEFT JOIN SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
WHERE ci.rn <= 10
ORDER BY di.gender_count DESC, total_sales DESC;
