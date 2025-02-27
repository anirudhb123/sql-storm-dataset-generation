
WITH RECURSIVE AddressTree AS (
    SELECT 
        ca_address_sk,
        ca_country,
        ca_state,
        ca_city,
        CAST(ca_street_number AS varchar(10)) || ' ' || ca_street_name || ' ' || COALESCE(ca_street_type, 'N/A') AS full_address,
        1 AS depth
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT 
        a.ca_address_sk,
        a.ca_country,
        a.ca_state,
        a.ca_city,
        CAST(a.ca_street_number AS varchar(10)) || ' ' || a.ca_street_name || ' ' || COALESCE(a.ca_street_type, 'N/A') AS full_address,
        at.depth + 1
    FROM customer_address a
    JOIN AddressTree at ON a.ca_state = at.ca_state AND a.ca_city <> at.ca_city
    WHERE at.depth < 3
),
ItemSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
AggregateDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS average_dependents,
        MAX(cd_credit_rating) AS highest_credit_rating 
    FROM customer_demographics
    WHERE cd_marital_status = 'M'
    GROUP BY cd_demo_sk, cd_gender
)
SELECT 
    a.depth,
    a.full_address,
    d.cd_gender,
    d.total_purchase_estimate,
    d.average_dependents,
    CASE 
        WHEN i.rn = 1 THEN 'Top Selling'
        WHEN i.order_count > 5 THEN 'Moderate Selling'
        ELSE 'Low Selling' 
    END AS sales_category
FROM AddressTree a
LEFT JOIN AggregateDemographics d ON a.ca_state = 'CA' AND a.ca_city = d.cd_gender
LEFT JOIN ItemSales i ON i.ws_item_sk = a.ca_address_sk
WHERE a.ca_country = 'USA' AND d.total_purchase_estimate IS NOT NULL 
ORDER BY a.depth DESC, d.total_purchase_estimate DESC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM customer WHERE c_first_name IS NULL) % 100;
