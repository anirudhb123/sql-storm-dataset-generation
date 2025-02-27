
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_address_id = (SELECT ca_address_id FROM customer_address WHERE ca_address_sk = ah.ca_address_sk)
    WHERE ca.ca_city IS NOT NULL AND ah.level < 5
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 1000
),
SummarizedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
    GROUP BY ws_bill_customer_sk
),
SalesComparison AS (
    SELECT 
        fc.c_customer_sk,
        fc.c_first_name,
        fc.c_last_name,
        ss.total_net_profit,
        ss.total_orders,
        CASE 
            WHEN ss.total_net_profit IS NULL THEN 'No Sales'
            WHEN ss.total_net_profit > 5000 THEN 'High Roller'
            ELSE 'Average Joe'
        END AS customer_status
    FROM FilteredCustomers fc
    LEFT JOIN SummarizedSales ss ON fc.c_customer_sk = ss.ws_bill_customer_sk
    WHERE fc.rn <= 5
)
SELECT
    ah.ca_city,
    ah.ca_state,
    sc.customer_status,
    COUNT(DISTINCT sc.c_customer_sk) AS customer_count,
    AVG(COALESCE(ss.total_net_profit, 0)) AS avg_net_profit
FROM AddressHierarchy ah
LEFT JOIN SalesComparison sc ON sc.c_customer_sk IN (
    SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ah.ca_address_sk
)
LEFT JOIN SummarizedSales ss ON sc.c_customer_sk = ss.ws_bill_customer_sk
GROUP BY ah.ca_city, ah.ca_state, sc.customer_status
ORDER BY ah.ca_city, ah.ca_state, customer_count DESC;
