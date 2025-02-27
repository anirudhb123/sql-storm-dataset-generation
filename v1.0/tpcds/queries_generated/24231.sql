
WITH RECURSIVE address_tree AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_state
    FROM customer_address ca
    INNER JOIN address_tree at ON ca.ca_address_sk = at.ca_address_sk - 1
),
customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(cd.cd_purchase_estimate) AS max_estimate,
        MIN(cd.cd_dep_count) AS min_dependents,
        SUM(COALESCE(cd.cd_dep_employed_count, 0)) OVER (PARTITION BY cd.cd_gender) AS total_employed_per_gender
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    GROUP BY ws.web_site_id
),
latest_orders AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_ship_date_sk DESC) AS rn
    FROM web_sales ws
),
final_summary AS (
    SELECT
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ad.ca_city,
        ad.ca_state,
        sd.total_sales,
        ld.ws_order_number
    FROM customer_info ci
    JOIN address_tree ad ON ci.c_customer_id = ad.ca_address_id
    LEFT JOIN sales_data sd ON ad.ca_city = sd.web_site_id
    LEFT JOIN latest_orders ld ON sd.web_site_id = ld.web_site_id AND ld.rn = 1
)
SELECT 
    COALESCE(fs.c_first_name, 'UNKNOWN') AS customer_first_name,
    COALESCE(fs.c_last_name, 'UNKNOWN') AS customer_last_name,
    fs.cd_gender,
    fs.ca_city,
    fs.ca_state,
    fs.total_sales,
    fs.ws_order_number
FROM final_summary fs
WHERE fs.total_sales IS NULL OR (fs.cd_gender = 'F' AND fs.total_sales > 5000)
ORDER BY fs.ca_state, fs.total_sales DESC
LIMIT 100
OFFSET 0;
