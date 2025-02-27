
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ca_country, 
        ca_street_name, 
        1 AS level
    FROM customer_address 
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT 
        a.ca_address_sk, 
        a.ca_city, 
        a.ca_state, 
        a.ca_country, 
        a.ca_street_name, 
        h.level + 1
    FROM customer_address a
    JOIN AddressHierarchy h ON a.ca_street_name LIKE CONCAT('%', h.ca_street_name, '%')
    WHERE h.level < 5
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT 
    a.ca_country,
    a.ca_state,
    cd.c_first_name,
    cd.c_last_name,
    COALESCE(cd.total_spent, 0) AS total_spent,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    COUNT(sd.ws_item_sk) AS item_count,
    SUM(sd.total_profit) AS total_profit
FROM AddressHierarchy a
FULL OUTER JOIN CustomerDetails cd ON a.ca_state = cd.cd_marital_status
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_item_sk AND sd.rn = 1
WHERE a.ca_country IS NOT NULL
AND (cd.total_spent > 100 OR cd.cd_gender IS NULL)
GROUP BY a.ca_country, a.ca_state, cd.c_first_name, cd.c_last_name, cd.cd_marital_status
ORDER BY total_profit DESC, item_count DESC
LIMIT 50 OFFSET 10;
