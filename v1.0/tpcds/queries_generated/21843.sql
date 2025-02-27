
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_order_number) AS cumulative_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_order_number DESC) AS rnk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
), 

MaxProfitableSite AS (
    SELECT 
        web_site_sk,
        MAX(cumulative_profit) AS max_profit
    FROM RankedSales
    WHERE rnk <= 10
    GROUP BY web_site_sk
),

SiteDetails AS (
    SELECT 
        w.w_warehouse_name, 
        count(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_bill_customer_sk IS NOT NULL 
    GROUP BY w.w_warehouse_name
),

CustomerActivity AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_spent,
        MIN(ws.ws_sold_date_sk) AS first_purchase,
        MAX(ws.ws_sold_date_sk) AS last_purchase
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
)

SELECT 
    ca.ca_city,
    SUM(sa.total_profit) AS city_total_profit,
    COUNT(DISTINCT ca.ca_address_sk) AS distinct_addresses,
    COALESCE(MAX(sa.order_count), 0) AS highest_order_count
FROM customer_address ca
LEFT JOIN SiteDetails sa ON ca.ca_city = sa.w_warehouse_name
LEFT JOIN CustomerActivity ca_activity ON ca_activity.total_orders > 5 AND ca_activity.avg_spent IS NOT NULL
WHERE ca.ca_state = 'CA' 
AND (ca.ca_country IS NULL OR ca.ca_country = 'USA')
GROUP BY ca.ca_city
HAVING SUM(sa.total_profit) > (SELECT MAX(max_profit) FROM MaxProfitableSite)
ORDER BY city_total_profit DESC NULLS LAST;
