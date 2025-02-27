
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state
    WHERE a.ca_country = ah.ca_country AND ah.level < 5
),
SalesSummary AS (
    SELECT
        CASE
            WHEN ws_sold_date_sk IS NULL THEN 'UNKNOWN DATE'
            ELSE d.d_date_id
        END AS sale_date,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_sales_price > 0
    GROUP BY sale_date
),
NullHandling AS (
    SELECT
        CASE
            WHEN cd_gender IS NULL OR cd_gender = 'U' THEN 'Gender Not Available'
            ELSE cd_gender
        END AS gender,
        COUNT(*) AS count
    FROM customer_demographics
    GROUP BY cd_gender
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    ah.ca_country,
    ss.total_sales,
    ss.total_orders,
    nh.gender,
    ROW_NUMBER() OVER (PARTITION BY ah.ca_state ORDER BY ss.total_sales DESC) as sales_rank,
    CASE 
        WHEN ss.total_orders = 0 THEN 'No Orders'
        ELSE CONCAT('Total Orders: ', ss.total_orders)
    END AS order_summary
FROM AddressHierarchy ah
LEFT JOIN SalesSummary ss ON ss.sale_date = 'UNKNOWN DATE'
LEFT JOIN NullHandling nh ON 1=1
WHERE ah.level IN (1, 2, 3)
ORDER BY ah.ca_country, ss.total_sales DESC
LIMIT 100;
