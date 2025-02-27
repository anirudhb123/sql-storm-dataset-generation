
WITH recent_web_sales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY ws.web_site_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk
    HAVING SUM(COALESCE(ws.ws_net_paid, 0)) > 1000
),
classifications AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    r.web_site_id,
    c.gender,
    SUM(hvc.total_spent) AS total_spent_by_gender,
    SUM(rp.total_net_profit) AS total_profit_by_site
FROM recent_web_sales rp
JOIN web_site r ON rp.web_site_sk = r.web_site_sk
FULL OUTER JOIN high_value_customers hvc ON hvc.c_customer_sk IN (
    SELECT DISTINCT c.c_customer_sk 
    FROM customer c 
    WHERE c.c_current_cdemo_sk IS NOT NULL
)
LEFT JOIN classifications c ON hvc.total_spent > 0
GROUP BY r.web_site_id, c.gender
HAVING SUM(hvc.total_spent) IS NOT NULL OR SUM(rp.total_net_profit) IS NOT NULL
ORDER BY total_spent_by_gender DESC, total_profit_by_site DESC;
