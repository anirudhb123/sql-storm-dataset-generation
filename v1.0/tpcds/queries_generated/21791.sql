
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, 
           ca_address_id,
           ca_street_number,
           ca_street_name,
           ca_street_type,
           ca_suite_number,
           ca_city,
           ca_county,
           ca_state,
           ca_zip,
           ca_country,
           ca_gmt_offset,
           CAST(ca_street_name AS VARCHAR(60)) || ' ' || COALESCE(ca_suite_number, '') AS full_address,
           1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'

    UNION ALL

    SELECT ca_address_sk, 
           ca_address_id,
           ca_street_number,
           ca_street_name,
           ca_street_type,
           ca_suite_number,
           ca_city,
           ca_county,
           ca_state,
           ca_zip,
           ca_country,
           ca_gmt_offset,
           CAST(ca_street_name AS VARCHAR(60)) || ' -> ' || full_address AS full_address,
           level + 1
    FROM AddressHierarchy
    JOIN customer_address ON ca_city = 'Los Angeles' AND level < 5
)

SELECT 
    cd_gender, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE 
            WHEN cd_marital_status = 'M' THEN 1 
            ELSE 0 
        END) AS married_count,
    SUM(CASE 
            WHEN cd_marital_status = 'S' THEN 1 
            ELSE 0 
        END) AS single_count,
    MAX(COALESCE(c.c_birth_year, 1970)) AS latest_birth_year,
    STRING_AGG(DISTINCT ca_city || ' ' || ca_state, ', ') FILTER (WHERE ca_state IS NOT NULL) AS locations
FROM customer c
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN AddressHierarchy ah ON ah.ca_address_sk = ca.ca_address_sk
WHERE 
    cd_purchase_estimate IS NOT NULL 
    AND ca_zip LIKE '9%' 
    AND (cd_credit_rating IS NULL OR cd_credit_rating = 'Unknown')
GROUP BY cd_gender
ORDER BY customer_count DESC;

WITH RecentReturns AS (
    SELECT 
        sr_returned_date_sk, 
        SUM(sr_return_quantity) AS total_returned,
        AVG(sr_return_amt) AS avg_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_returned_date_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM store_returns
    GROUP BY sr_returned_date_sk
)
SELECT 
    d.d_date AS return_date,
    COALESCE(rr.total_returned, 0) AS total_returned,
    rr.avg_return_amt
FROM date_dim d
LEFT JOIN RecentReturns rr ON d.d_date_sk = rr.sr_returned_date_sk
WHERE d.d_year = 2023 AND (d.d_dow IN (1, 2, 3) OR d.d_weekend = 'Y')
ORDER BY return_date;

SELECT 
    DISTINCT CONCAT(p.p_promo_name, ' (ID: ', p.p_promo_id, ')') AS promo_details, 
    COUNT(*) AS promo_usage,
    SUM(ws_sales_price) AS total_sales
FROM promotion p
JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
WHERE 
    p.p_discount_active = 'Y' 
    AND p.p_start_date_sk <= CURRENT_DATE 
    AND p.p_end_date_sk >= CURRENT_DATE 
GROUP BY promo_details
HAVING COUNT(*) > 5
ORDER BY total_sales DESC;

SELECT 
    DISTINCT ca_state,
    SUM(ws_net_profit) AS total_net_profit,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ws_net_profit) OVER (PARTITION BY ca_state) AS seventy_five_percentile
FROM web_sales ws
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
WHERE ca_state IS NOT NULL
GROUP BY ca_state
HAVING COUNT(DISTINCT ws.ws_item_sk) > 10 OR SUM(ws_net_profit) IS NULL;
