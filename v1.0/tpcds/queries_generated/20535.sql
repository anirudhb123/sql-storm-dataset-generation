
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_country, ca_state, ca_city, ca_address_id, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_country, ca.ca_state, ca.ca_city, ca.ca_address_id, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_city <> ah.ca_city
    WHERE ah.level < 5
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
CustomerStats AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_profit,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN CustomerSales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
ShippingStatistics AS (
    SELECT 
        sm.sm_type,
        COUNT(ws.ws_order_number) AS shipping_count,
        AVG(ws.ws_ext_ship_cost) AS average_ship_cost,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
)
SELECT 
    ah.ca_city,
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.sales_rank,
    st.sm_type,
    st.shipping_count,
    st.average_ship_cost,
    st.total_sales AS total_shipping_sales,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    CONCAT('Customer ID: ', cs.c_customer_id, ' resides in ', ah.ca_city) AS customer_location
FROM AddressHierarchy ah
JOIN CustomerSales cs ON ah.ca_address_id = cs.c_customer_id
JOIN ShippingStatistics st ON cs.order_count > 0
WHERE ah.level = 1 AND ah.ca_country IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM CustomerStats
        WHERE total_profit > 1000
    )
ORDER BY total_sales DESC
LIMIT 50;
