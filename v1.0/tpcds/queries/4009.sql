
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.order_count,
        co.total_spent,
        co.avg_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer_demographics cd ON co.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.order_count,
    hs.total_spent,
    hs.avg_spent,
    ROW_NUMBER() OVER (PARTITION BY hs.order_count ORDER BY hs.total_spent DESC) AS rank,
    COALESCE(
        (SELECT 
            sm.sm_type 
         FROM 
            ship_mode sm 
         WHERE 
            sm.sm_ship_mode_sk = 
                (SELECT 
                    ws.ws_ship_mode_sk 
                 FROM 
                    web_sales ws 
                 WHERE 
                    ws.ws_bill_customer_sk = hs.c_customer_sk 
                 ORDER BY 
                    ws.ws_sold_date_sk DESC 
                 LIMIT 1)
         ), 'No Shipping Method') AS last_shipping_method
FROM 
    HighSpenders hs
WHERE 
    hs.avg_spent > 100
ORDER BY 
    hs.total_spent DESC;
