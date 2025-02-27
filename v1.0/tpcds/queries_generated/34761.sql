
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        0 AS level
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT 
        a.ca_address_sk,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        h.level + 1 
    FROM customer_address a
    JOIN AddressHierarchy h ON h.ca_city = a.ca_city AND h.ca_state = a.ca_state AND h.level < 2
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(d.cd_gender, 'N/A') AS gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(d.cd_gender, 'N/A') ORDER BY d.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesSummary AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        ws_ship_mode_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_tax) AS total_tax
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10)
    GROUP BY ws_ship_mode_sk
)
SELECT 
    ci.gender,
    ci.marital_status,
    ah.ca_city,
    ah.ca_state,
    ah.ca_country,
    ss.total_sales,
    ss.order_count,
    ss.total_tax
FROM CustomerInfo ci
JOIN AddressHierarchy ah ON ci.ca_city = ah.ca_city AND ci.ca_state = ah.ca_state
FULL OUTER JOIN SalesSummary ss ON ss.ws_ship_mode_sk = (
    SELECT sm_ship_mode_sk 
    FROM ship_mode 
    WHERE sm_code IN ('Air', 'Ground') 
    LIMIT 1
)
WHERE (ci.gender_rank = 1 OR ss.order_count > 100)
ORDER BY ss.total_sales DESC, ah.level, ci.gender;
