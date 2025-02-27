
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        RANK() OVER(PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_sales
    FROM web_sales
    GROUP BY ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High spender'
            ELSE 'Low spender' 
        END AS customer_segment
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IS NOT NULL
    AND cd.cd_dep_count > 0
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state, 
        CASE 
            WHEN ca.ca_state IS NULL THEN 'Unknown'
            ELSE ca.ca_state 
        END AS address_state
    FROM customer_address ca
    WHERE ca.ca_city IS NOT NULL
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ws.total_quantity) AS total_bought,
    SUM(ws.total_net_paid) AS total_spent,
    ad.address_state
FROM RankedSales ws
JOIN web_sales w ON ws.ws_item_sk = w.ws_item_sk
JOIN HighValueCustomers c ON w.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
WHERE c.customer_segment = 'High spender'
AND (ws.total_quantity > 0 OR ws.total_net_paid > 100)
GROUP BY c.c_first_name, c.c_last_name, ad.address_state
HAVING SUM(ws.total_net_paid) > 500
ORDER BY total_spent DESC, total_bought ASC
LIMIT 50;
