
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High' 
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS spending_band
    FROM 
        CustomerStats cs
    WHERE 
        cs.rank <= 10
), 
ShippingMethods AS (
    SELECT 
        ws.ws_ship_mode_sk,
        sm.sm_type,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_ship_mode_sk, sm.sm_type
)
SELECT 
    hs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    hs.total_orders,
    hs.total_spent,
    hs.spending_band,
    sm.avg_order_value,
    round(sm.avg_order_value * (SELECT AVG(total_spent) FROM HighSpenders), 2) AS adjusted_avg_order_value
FROM 
    HighSpenders hs
LEFT JOIN 
    CustomerStats cs ON hs.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    ShippingMethods sm ON sm.ws_ship_mode_sk = (
        SELECT ws.ws_ship_mode_sk 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = hs.c_customer_sk 
        ORDER BY ws.ws_sold_date_sk DESC LIMIT 1
    )
WHERE 
    hs.total_orders > 0
ORDER BY 
    hs.total_spent DESC
LIMIT 100;
