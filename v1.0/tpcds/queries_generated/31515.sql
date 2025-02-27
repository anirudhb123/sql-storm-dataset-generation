
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        1 AS level
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_ship_customer_sk
    
    UNION ALL
    
    SELECT 
        sr.sr_returning_customer_sk,
        SUM(-sr.sr_return_amt_inc_tax) AS total_profit,
        level + 1
    FROM store_returns sr
    JOIN sales_hierarchy sh ON sr.sr_returning_customer_sk = sh.ws_ship_customer_sk
    GROUP BY sr.sr_returning_customer_sk
),
customer_profit AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(sh.total_profit) AS total_profit,
        CASE 
            WHEN SUM(sh.total_profit) IS NULL THEN 'No Sales'
            WHEN SUM(sh.total_profit) > 0 THEN 'Profitable'
            ELSE 'Not Profitable'
        END AS profitability_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_hierarchy sh ON sh.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
)
SELECT 
    cp.c_customer_id,
    cp.cd_gender,
    cp.total_profit,
    cp.profitability_status,
    ca.ca_city,
    ca.ca_state,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = cp.c_customer_sk
     AND ws.ws_sales_price > 100) AS large_orders_count
FROM customer_profit cp
JOIN customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cp.c_customer_sk)
WHERE (cp.total_profit > 500 OR cp.profitability_status = 'No Sales')
ORDER BY cp.total_profit DESC
LIMIT 100;
