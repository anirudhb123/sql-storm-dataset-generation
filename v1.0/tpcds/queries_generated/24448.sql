
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL AND ws_net_profit IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT w.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM RankedSales rs
    WHERE rs.rn = 1
    GROUP BY rs.ws_item_sk
    HAVING SUM(rs.ws_net_profit) > 1000
),
CustomerAndItems AS (
    SELECT 
        cd.c_customer_id,
        hpi.ws_item_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM CustomerDetails cd
    JOIN HighProfitItems hpi ON cd.total_orders > (SELECT AVG(total_orders) FROM CustomerDetails)
    ORDER BY cd.cd_marital_status, cd.cd_gender
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cai.c_customer_id) AS number_of_customers,
    COALESCE(SUM(hpi.total_net_profit), 0) AS total_high_profit
FROM customer_address ca
LEFT JOIN CustomerAndItems cai ON ca.ca_address_sk = 
    (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = cai.c_customer_id LIMIT 1)
LEFT JOIN HighProfitItems hpi ON cai.ws_item_sk = hpi.ws_item_sk
WHERE ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT cai.c_customer_id) > 5
ORDER BY number_of_customers DESC, total_high_profit DESC
LIMIT 10;
