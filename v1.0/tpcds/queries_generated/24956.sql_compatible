
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ws.ws_quantity) AS total_web_quantity,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_orders,
        cs.total_web_profit,
        cs.total_web_quantity
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_web_profit > (SELECT AVG(total_web_profit) FROM CustomerStats)
),
RecentPurchases AS (
    SELECT 
        ws.ws_ship_customer_sk,
        MAX(dd.d_date) AS last_purchase_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_ship_customer_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_orders,
    hvc.total_web_profit,
    COALESCE(rp.last_purchase_date, 'No purchases') AS last_purchase_date,
    CASE 
        WHEN hvc.total_web_quantity > 100 THEN 'High Quantity'
        ELSE 'Low Quantity'
    END AS purchase_category,
    CASE 
        WHEN hvc.total_web_profit > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentPurchases rp ON hvc.c_customer_sk = rp.ws_ship_customer_sk
WHERE 
    hvc.total_web_orders > 0
ORDER BY 
    hvc.total_web_profit DESC,
    hvc.c_last_name ASC;
