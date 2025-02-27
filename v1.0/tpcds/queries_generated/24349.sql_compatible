
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer_stats cs
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cs.rn <= 10
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.cd_gender
),
average_profit AS (
    SELECT 
        cd.cd_gender,
        AVG(ts.total_profit) AS avg_profit
    FROM 
        top_customers ts
    JOIN 
        customer_demographics cd ON ts.cd_gender = cd.cd_gender
    GROUP BY 
        cd.cd_gender
)
SELECT 
    a.cd_gender,
    COALESCE(a.avg_profit, 0) AS avg_profit,
    MAX(ts.total_profit) AS max_profit
FROM 
    average_profit a
LEFT JOIN
    top_customers ts ON a.cd_gender = ts.cd_gender
GROUP BY 
    a.cd_gender
HAVING 
    MAX(ts.total_profit) > (SELECT AVG(ts2.total_profit) FROM top_customers ts2 WHERE ts2.cd_gender = a.cd_gender)
ORDER BY 
    a.cd_gender;
