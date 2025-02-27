
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(cd.cd_gender, 'U') ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.gender,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.order_count > 1 AND cs.total_profit > 1000
),
AggregateShipping AS (
    SELECT 
        ws.ws_ship_mode_sk,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 10000
    GROUP BY 
        ws.ws_ship_mode_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(hu.total_profit, 0) AS high_value_profit,
    COALESCE(hu.profit_rank, 'N/A') AS profit_rank,
    ASW.warehouse_id,
    ASW.as_of_date,
    shipping.total_ship_cost,
    CASE 
        WHEN shipping.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS shipping_status
FROM 
    customer c
LEFT JOIN 
    HighValueCustomers hu ON c.c_customer_sk = hu.c_customer_sk
LEFT JOIN 
    (SELECT w.w_warehouse_id, d.d_date AS as_of_date
     FROM warehouse w
     CROSS JOIN date_dim d
     WHERE d.d_date = (SELECT MAX(d2.d_date) FROM date_dim d2)) ASW ON 1=1
LEFT JOIN 
    AggregateShipping shipping ON shipping.ws_ship_mode_sk = 
        (SELECT sm.sm_ship_mode_sk 
         FROM ship_mode sm 
         WHERE sm.sm_carrier LIKE '%FedEx%'
         LIMIT 1)
WHERE 
    (c.c_birth_year IS NULL OR c.c_birth_year < 1980)
    AND (ASW.as_of_date IS NOT NULL OR hu.total_profit IS NOT NULL)
ORDER BY 
    c.c_last_name ASC NULLS FIRST,
    hu.high_value_profit DESC;
