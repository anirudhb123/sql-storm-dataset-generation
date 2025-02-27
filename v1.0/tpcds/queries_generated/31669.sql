
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT
        ws.ws_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS average_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_customer_sk
),
DemographicData AS (
    SELECT
        cd.cd_demo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        CASE 
            WHEN AVG(cd.cd_dep_count) IS NULL THEN 'No Dependents'
            WHEN AVG(cd.cd_dep_count) > 0 THEN 'Has Dependents'
            ELSE 'No Dependents'
        END AS dependent_status
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk
)
SELECT
    C.c_first_name,
    C.c_last_name,
    COALESCE(SD.total_sales, 0) AS total_sales,
    COALESCE(SD.average_sales, 0) AS average_sales,
    COALESCE(SD.order_count, 0) AS order_count,
    D.max_purchase_estimate,
    D.dependent_status,
    CH.level
FROM CustomerHierarchy CH
LEFT JOIN SalesData SD ON CH.c_customer_sk = SD.ws_customer_sk
LEFT JOIN DemographicData D ON CH.c_current_cdemo_sk = D.cd_demo_sk
LEFT JOIN customer C ON CH.c_customer_sk = C.c_customer_sk
WHERE C.c_birth_year >= (SELECT MAX(d.d_year) FROM date_dim d WHERE d.d_current_year = 'Y') - 30
AND (SD.total_sales IS NOT NULL OR D.dependent_status = 'Has Dependents')
ORDER BY total_sales DESC, C.c_last_name ASC
LIMIT 100;
