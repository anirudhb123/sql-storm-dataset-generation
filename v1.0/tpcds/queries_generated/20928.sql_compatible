
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY') AND ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM customer_address AS ca
    JOIN AddressCTE AS cte ON cte.ca_city = ca.ca_city
    WHERE ca_state NOT IN ('TX')
),
CustomerDemographics AS (
    SELECT cd_demo_sk, cd_gender, 
           COUNT(DISTINCT c_customer_sk) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender
),
ItemSales AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
SalesSummary AS (
    SELECT i.i_item_id, 
           COALESCE(s.total_quantity, 0) AS total_quantity,
           COALESCE(s.total_profit, 0.00) AS total_profit,
           ROW_NUMBER() OVER (ORDER BY COALESCE(s.total_profit, 0.00) DESC) AS profit_rank
    FROM item AS i
    LEFT JOIN ItemSales AS s ON i.i_item_sk = s.ws_item_sk
)
SELECT ca.ca_city, ca.ca_state, 
       COUNT(DISTINCT c.c_customer_sk) AS total_customers, 
       SUM(COALESCE(ss.total_quantity, 0)) AS total_item_sold,
       AVG(cd.avg_purchase_estimate) AS avg_purchase_by_gender,
       (SELECT COUNT(*) 
        FROM (
            SELECT DISTINCT cd_gender 
            FROM CustomerDemographics
            WHERE customer_count > 5
        ) AS sub) AS distinct_genders
FROM AddressCTE ca
JOIN CustomerDemographics cd ON cd.customer_count > 10
LEFT JOIN web_sales ws ON ws.ws_bill_addr_sk IN (SELECT ca_address_sk FROM AddressCTE WHERE address_rank < 10)
LEFT JOIN SalesSummary ss ON ss.i_item_id = ws.ws_item_sk
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_city NOT LIKE '%ville%'
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(COALESCE(ss.total_profit, 0)) > 10000
ORDER BY total_customers DESC, total_item_sold DESC;
