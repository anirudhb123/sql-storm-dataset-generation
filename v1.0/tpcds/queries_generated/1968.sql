
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS rank
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
TopShippingModes AS (
    SELECT 
        sm.sm_type, 
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
    ORDER BY 
        COUNT(ws.ws_order_number) DESC
    LIMIT 3
)
SELECT 
    hvc.c_customer_id,
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS full_name,
    hvc.cd_gender,
    COALESCE(rtr.total_return_amt, 0) AS total_return_amt,
    COALESCE(rtr.return_count, 0) AS return_count,
    sm.order_count AS top_shipping_mode_orders
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RankedReturns rtr ON hvc.c_customer_id = rtr.wr_returning_customer_sk
JOIN 
    TopShippingModes sm ON sm.order_count > 10
WHERE 
    hvc.total_spent IS NOT NULL
ORDER BY 
    hvc.total_spent DESC;
