
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_first_name IS NOT NULL 
        AND (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopItems AS (
    SELECT 
        ris.ws_item_sk,
        SUM(ris.ws_net_profit) AS total_net_profit
    FROM RankedSales ris
    WHERE ris.rank_profit <= 5
    GROUP BY ris.ws_item_sk
    HAVING SUM(ris.ws_net_profit) > 1000
)
SELECT 
    ca.ca_city,
    SUM(ti.total_net_profit) AS city_total_profit,
    COUNT(DISTINCT ca.ca_address_id) AS shipping_addresses,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customers,
    CASE WHEN COUNT(DISTINCT c.c_customer_sk) > 10 THEN 'Y' ELSE 'N/A' END AS high_value_customers
FROM customer_address ca
JOIN TopItems ti ON ti.ws_item_sk = ca.ca_address_sk
JOIN CustomerAnalysis c ON c.c_customer_sk = ca.ca_address_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY ca.ca_city
ORDER BY city_total_profit DESC
LIMIT 10;
