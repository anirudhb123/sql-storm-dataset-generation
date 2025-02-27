
WITH RECURSIVE AddressTree AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) as rn
    FROM customer_address
    WHERE ca_state IS NOT NULL
),
AddressCounts AS (
    SELECT ca_city, COUNT(*) as address_count
    FROM customer_address
    GROUP BY ca_city
    HAVING COUNT(*) > 5
),
CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           RANK() OVER (PARTITION BY c.c_current_addr_sk ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT a.ca_city, a.ca_state,
       SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
       MAX(ci.purchase_rank) AS max_rank,
       COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
       CASE 
           WHEN a.ca_zip IS NULL THEN 'UNKNOWN ZIP'
           ELSE a.ca_zip
       END AS normalized_zip
FROM AddressTree a
LEFT JOIN web_sales ws ON a.ca_city = ws.ws_bill_addr_sk
LEFT JOIN CustomerInfo ci ON a.ca_address_sk = ci.c_customer_sk
WHERE a.rn <= 10 
AND a.ca_city IN (SELECT ca_city FROM AddressCounts)
AND (ws.ws_sales_price > 100 OR ws.ws_net_profit IS NULL)
GROUP BY a.ca_city, a.ca_state
HAVING MAX(ci.purchase_rank) > 1
ORDER BY total_profit DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
