
WITH RECURSIVE CustomerRank AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_marital_status, 
        cd_gender, 
        cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd_marital_status ORDER BY cd_dep_count DESC) AS rank
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_dep_count IS NOT NULL
),
DateRange AS (
    SELECT 
        d_date_sk, 
        d_date,
        d_year
    FROM date_dim
    WHERE d_date BETWEEN '2021-01-01' AND '2021-12-31'
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_ship_date_sk) AS last_order_date
    FROM web_sales
    WHERE ws_ship_date_sk IN (SELECT d_date_sk FROM DateRange)
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.order_count,
    cs.last_order_date,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Purchases'
        ELSE 'Regular Customer'
    END AS customer_status,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(NULLIF(cd.cd_gender, 'F'), 'N/A') AS gender,
    cr.return_count,
    COALESCE(cr.return_count, 0) * 100.0 / NULLIF(cs.order_count, 0) AS return_rate
FROM customer AS c
LEFT JOIN (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS return_count 
    FROM store_returns 
    GROUP BY sr_customer_sk
) AS cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN SalesSummary AS cs ON c.c_customer_sk = cs.customer_id
LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_year < 1980
AND (cd_dep_count IS NULL OR cd_dep_count > 1)
UNION ALL
SELECT 
    r.customer_id,
    r.first_name,
    r.last_name,
    r.total_sales,
    r.order_count,
    r.last_order_date,
    'Inactive Customer' AS customer_status,
    'Unknown' AS city,
    'N/A' AS gender,
    0 AS return_count,
    0 AS return_rate
FROM (
    SELECT 
        c.c_customer_sk AS customer_id, 
        c.c_first_name AS first_name, 
        c.c_last_name AS last_name, 
        COUNT(wr_order_number) AS total_sales,
        COUNT(DISTINCT wr_order_number) AS order_count,
        MAX(wr_returned_date_sk) AS last_order_date
    FROM web_returns
    LEFT JOIN customer AS c ON wr_returning_customer_sk = c.c_customer_sk
    WHERE wr_returned_date_sk < 2021
    GROUP BY c.c_customer_sk
) AS r
WHERE r.total_sales = 0
ORDER BY total_sales DESC, c_last_name, c_first_name;
