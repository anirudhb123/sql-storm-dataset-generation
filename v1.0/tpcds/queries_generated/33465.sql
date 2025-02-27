
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
Address_CTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
Demographics_CTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_income_band_sk,
        COUNT(*) AS demo_count
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_income_band_sk
)
SELECT 
    s.ws_item_sk,
    SUM(s.ws_quantity) AS total_quantity,
    AVG(s.ws_sales_price) AS average_sales_price,
    MIN(s.ws_net_paid) AS min_net_paid,
    MAX(s.ws_net_paid) AS max_net_paid,
    COALESCE(demo.cd_gender, 'Unknown') AS customer_gender,
    d.demo_count,
    aa.full_address,
    ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY SUM(s.ws_quantity) DESC) AS rank
FROM 
    Sales_CTE s
LEFT JOIN 
    Demographics_CTE demo ON s.ws_item_sk = demo.cd_demo_sk
LEFT JOIN 
    Address_CTE aa ON aa.ca_address_sk = s.ws_item_sk
WHERE 
    s.rn = 1
GROUP BY 
    s.ws_item_sk, demo.cd_gender, d.demo_count, aa.full_address
HAVING 
    SUM(s.ws_quantity) > 10
ORDER BY 
    total_quantity DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
