
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS ranking
    FROM
        web_sales
    GROUP BY
        ws_item_sk
    HAVING
        SUM(ws_net_profit) > 1000
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN cd_demo_sk END) AS female_customers,
        COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN cd_demo_sk END) AS male_customers,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_customers,
        COUNT(*) AS total_customers
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY
        c.c_customer_sk
),
ShippingModes AS (
    SELECT
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(ws1.ws_sold_date_sk) FROM web_sales ws1)
    GROUP BY
        sm.sm_ship_mode_id
)
SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS average_profit,
    COALESCE(cs.total_customers, 0) AS total_customers,
    cs.female_customers,
    cs.male_customers,
    STRING_AGG(DISTINCT sm_type, ', ') AS shipping_types
FROM
    customer_address ca
LEFT JOIN
    store_sales ss ON ca.ca_address_sk = ss.ss_addr_sk
LEFT JOIN
    CustomerStats cs ON cs.c_customer_sk = ss.ss_customer_sk
JOIN
    ShippingModes sm ON sm.order_count > 10
WHERE
    ca.ca_state IS NOT NULL
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    SUM(ss_ext_sales_price) > (SELECT AVG(total_profit) FROM SalesCTE)
ORDER BY
    total_sales DESC
LIMIT 10;
