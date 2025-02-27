
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, 
           ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.c_current_cdemo_sk, 
           ROW_NUMBER() OVER (PARTITION BY ch.c_current_cdemo_sk ORDER BY ch.c_customer_sk)
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.rn < 5  -- Limit to 5 levels
),
customer_details AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           (COALESCE(cd.cd_dep_count, 0) + COALESCE(cd.cd_dep_employed_count, 0)) AS total_deps,
           da.ca_city, da.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address da ON c.c_current_addr_sk = da.ca_address_sk
),
total_sales AS (
    SELECT 
        ws.ws_ship_customer_sk AS customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_deps, 
    cd.ca_city, 
    cd.ca_state,
    COALESCE(ts.total_sales_price, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    CASE 
        WHEN cd.cd_gender = 'F' AND ts.total_sales_price > 1000 THEN 'High Value Female'
        WHEN cd.cd_gender = 'M' AND ts.total_sales_price > 1000 THEN 'High Value Male'
        ELSE 'Regular Customer' 
    END AS customer_segment
FROM customer_hierarchy ch
JOIN customer_details cd ON ch.c_customer_sk = cd.c_customer_sk
LEFT JOIN total_sales ts ON ch.c_customer_sk = ts.customer_id
WHERE cd.ca_state = 'CA' AND ts.total_sales_price IS NOT NULL
ORDER BY total_sales DESC
LIMIT 100;
