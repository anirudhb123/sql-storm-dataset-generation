
WITH RecursiveSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    GROUP BY ws.web_site_id, ws.ws_sold_date_sk
),
SalesDetails AS (
    SELECT 
        r.web_site_id,
        d.d_date,
        r.total_profit,
        r.total_orders,
        (r.total_profit / NULLIF(r.total_orders, 0)) AS avg_profit_per_order,
        CASE 
            WHEN r.total_orders > 100 THEN 'High'
            WHEN r.total_orders BETWEEN 51 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS order_category
    FROM RecursiveSales r
    JOIN date_dim d ON r.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
)
SELECT 
    sd.web_site_id,
    sd.d_date,
    sd.total_profit,
    sd.total_orders,
    sd.avg_profit_per_order,
    sd.order_category
FROM SalesDetails sd
WHERE sd.rank = 1
  AND sd.order_category = 'High'
  AND sd.total_profit > (SELECT AVG(total_profit) FROM SalesDetails)
ORDER BY sd.total_profit DESC
LIMIT 10;

-- Additional Queries for performance benchmarking
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(st.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT st.ss_ticket_number) AS total_transactions
FROM customer c
LEFT JOIN store_sales st ON c.c_customer_sk = st.ss_customer_sk
WHERE c.c_birth_year = 1990
GROUP BY c.c_first_name, c.c_last_name
HAVING total_net_profit > 5000
ORDER BY total_net_profit DESC;

UNION ALL

SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_transactions
FROM customer c
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE c.c_birth_year = 1990
GROUP BY c.c_first_name, c.c_last_name
HAVING total_net_profit > 5000
ORDER BY total_net_profit DESC;
