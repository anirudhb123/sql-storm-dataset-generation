
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON c.c_customer_sk = ws.bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY ws.bill_customer_sk
    HAVING SUM(ws.net_profit) > (
        SELECT AVG(total_net_profit) 
        FROM (
            SELECT SUM(ws_inner.net_profit) AS total_net_profit
            FROM web_sales ws_inner
            GROUP BY ws_inner.bill_customer_sk
        ) AS avg_sales
    )
), 
filtered_customers AS (
    SELECT 
        c.c_customer_id,
        ca.city,
        ca.state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 500
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
)
SELECT 
    f.c_customer_id,
    f.city,
    f.state,
    sh.total_net_profit,
    CASE 
        WHEN sh.rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_tier
FROM filtered_customers f
LEFT JOIN sales_hierarchy sh ON f.c_customer_id = sh.bill_customer_sk
WHERE f.state IN (SELECT DISTINCT w.w_state FROM warehouse w WHERE w.w_warehouse_sq_ft > 10000)
ORDER BY sh.total_net_profit DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;

SELECT DISTINCT 
    s.s_city,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM store s
JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
WHERE s.s_closed_date_sk IS NULL
GROUP BY s.s_city
HAVING COUNT(DISTINCT ss.ss_ticket_number) > (
    SELECT COUNT(DISTINCT sr_ticket_number)
    FROM store_returns sr
    WHERE sr_return_quantity > 0
)
ORDER BY total_net_profit DESC;

UNION ALL

SELECT 
    'N/A' AS s_city,
    COUNT(DISTINCT sr_ticket_number) AS total_sales,
    SUM(sr.net_loss) AS total_net_profit
FROM store_returns sr
WHERE sr_return_quantity IS NULL
GROUP BY sr.store_sk
HAVING SUM(sr.net_loss) < 0;
