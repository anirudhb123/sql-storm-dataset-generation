
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country, level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ah.ca_city = ca.ca_city AND ah.level < 5
),
ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        COUNT(*) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
    AND ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        CASE
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        COALESCE(cd_marital_status, 'Single') AS marital_status,
        cd_purchase_estimate,
        SUM(COALESCE(hd_dep_count, 0)) OVER (PARTITION BY c.c_customer_sk) AS total_dependents
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
shipment_info AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        sm.sm_carrier,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost
    FROM web_sales ws
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws.ws_order_number, ws.ws_item_sk, sm.sm_carrier
)
SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(WINDOW_SUM.total_sales) AS total_sales,
    STRING_AGG(DISTINCT CASE WHEN ranked_sales.sales_rank = 1 THEN CAST(rank AS varchar) END) AS top_ranks,
    AVG(shipment_info.total_ship_cost) AS average_ship_cost,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
FROM address_hierarchy ca
LEFT JOIN ranked_sales ON ranked_sales.ws_item_sk IN (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_dow BETWEEN 1 AND 5)
)
JOIN shipment_info ON shipment_info.ws_item_sk = ranked_sales.ws_item_sk
JOIN customer_data cd ON cd.c_customer_sk = (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_current_addr_sk = (
        SELECT ca.ca_address_sk
        FROM customer_address ca
        WHERE ca.ca_city = ca.ca_city AND ca.ca_state = ca.ca_state
        LIMIT 1
    )
)
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT cd.c_customer_sk) > 10
ORDER BY total_sales DESC
LIMIT 10;
