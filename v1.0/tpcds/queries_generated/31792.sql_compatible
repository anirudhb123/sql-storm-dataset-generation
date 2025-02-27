
WITH RECURSIVE SalesAnalysis AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_sk
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        SUM(ws.net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        total_orders,
        total_profit
    FROM SalesAnalysis
    WHERE rank <= 5
)
SELECT 
    tw.web_site_sk,
    tw.total_orders,
    tw.total_profit,
    COALESCE(ca.gender, 'Unknown') AS customer_gender,
    SUM(ca.total_profit) AS gender_based_profit
FROM TopWebsites tw
LEFT JOIN CustomerAnalysis ca ON tw.web_site_sk = ca.c_customer_sk
GROUP BY tw.web_site_sk, tw.total_orders, tw.total_profit, ca.gender
ORDER BY tw.total_profit DESC
LIMIT 10;
