
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           NULL::INTEGER AS parent_customer_sk, 
           0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ch.c_customer_sk AS parent_customer_sk, 
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_sold_date_sk
),
CustomerSummary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT CASE WHEN cd_cdmarital_status = 'S' THEN c.c_customer_sk END) AS single_customers,
        SUM(COALESCE(cd_purchase_estimate, 0)) AS total_estimated_purchase
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT
    cs.ca_state,
    cs.customer_count,
    cs.single_customers,
    cs.total_estimated_purchase,
    COALESCE(sd.total_net_paid, 0) AS total_net_paid,
    sd.total_orders,
    RANK() OVER (PARTITION BY cs.ca_state ORDER BY cs.total_estimated_purchase DESC) AS state_ranking
FROM CustomerSummary cs
LEFT JOIN SalesData sd ON cs.ca_state = (
    SELECT MAX(CASE WHEN ca.ca_state = 'US' THEN 'US' ELSE 'Other' END) 
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
WHERE cs.total_estimated_purchase > 0
ORDER BY cs.ca_state, state_ranking DESC;
