
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_current_cdemo_sk = cc.c_customer_sk
    WHERE level < 3
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
AddressDetails AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
)
SELECT
    cte.c_first_name,
    cte.c_last_name,
    ss.total_orders,
    ss.total_sales,
    ss.total_profit,
    ad.ca_city,
    ad.customer_count,
    ROW_NUMBER() OVER (PARTITION BY ad.ca_city ORDER BY ss.total_profit DESC) AS city_rank,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 10000 THEN 'High Roller'
        ELSE 'Average Joe'
    END AS customer_type,
    (SELECT MAX(ws_ship_date_sk) 
     FROM web_sales ws 
     WHERE ws_bill_customer_sk = cte.c_customer_sk) AS last_purchase_date
FROM CustomerCTE cte
JOIN SalesSummary ss ON cte.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN AddressDetails ad ON cte.c_current_cdemo_sk = ad.customer_count
WHERE ad.customer_count IS NOT NULL
UNION
SELECT 
    'N/A' AS c_first_name,
    'N/A' AS c_last_name,
    ss.total_orders,
    ss.total_sales,
    ss.total_profit,
    ad.ca_city,
    ad.customer_count,
    NULL AS city_rank,
    'Missing Customer' AS customer_type,
    NULL AS last_purchase_date
FROM SalesSummary ss
FULL OUTER JOIN AddressDetails ad ON ss.ws_bill_customer_sk = ad.customer_count
WHERE ss.total_profit < 100
ORDER BY customer_type, total_profit DESC;
