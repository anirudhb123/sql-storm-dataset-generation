
WITH addr AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        CONCAT(ca_zip, ', ', ca_state) AS zip_state
    FROM customer_address
),
demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer_demographics
),
item_details AS (
    SELECT 
        i_item_id,
        i_item_desc,
        i_current_price,
        i_brand
    FROM item
),
sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    addr.full_address,
    addr.city_lower,
    demo.cd_gender,
    demo.cd_marital_status,
    item.i_item_desc,
    item.i_current_price,
    item.total_sales,
    COUNT(ws.web_site_sk) AS total_websites
FROM addr
JOIN demographics demo ON demo.cd_demo_sk IN (
    SELECT c_current_cdemo_sk 
    FROM customer 
    WHERE c_current_addr_sk IS NOT NULL
)
JOIN item_details item ON item.i_item_id IN (
    SELECT ws_item_sk 
    FROM sales 
    WHERE total_sales > 1000
)
JOIN web_site ws ON LOWER(ws.web_name) LIKE '%' || addr.city_lower || '%'
GROUP BY addr.full_address, addr.city_lower, demo.cd_gender, demo.cd_marital_status, item.i_item_desc, item.i_current_price
ORDER BY total_sales DESC, addr.full_address;
