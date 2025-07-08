
WITH AddressConcat AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               (CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END), 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
DemoGender AS (
    SELECT
        cd_demo_sk,
        COUNT(*) AS customer_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM customer_demographics
    GROUP BY cd_demo_sk
),
ItemDetails AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand,
        i_category
    FROM item
)
SELECT 
    a.full_address,
    d.customer_count,
    d.male_count,
    d.female_count,
    i.i_item_desc,
    i.i_current_price,
    i.i_brand,
    i.i_category
FROM 
    AddressConcat a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    DemoGender d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    ItemDetails i ON i.i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = c.c_customer_sk)
WHERE 
    d.customer_count > 1
ORDER BY 
    a.full_address, d.customer_count DESC, i_current_price DESC
LIMIT 100;
