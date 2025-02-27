
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.total_orders
    FROM 
        CustomerStatistics cs
    WHERE 
        cs.rnk <= 10
),
TotalSales AS (
    SELECT 
        SUM(ws.ws_net_profit) as all_time_sales
    FROM 
        web_sales ws
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    ts.all_time_sales,
    COALESCE((SELECT COUNT(*) 
               FROM store_returns sr 
               WHERE sr.sr_customer_sk = tc.c_customer_sk), 0) AS total_returns,
    CASE 
        WHEN tc.total_orders = 0 THEN 0
        ELSE ROUND(tc.total_net_profit / tc.total_orders, 2)
    END AS avg_order_value,
    (SELECT 
        DISTINCT w.w_warehouse_name 
     FROM 
        warehouse w 
     JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk 
     WHERE 
        i.inv_quantity_on_hand > 0
        AND EXISTS (SELECT 1 
                    FROM web_sales ws 
                    WHERE ws.ws_item_sk = i.inv_item_sk 
                    AND ws.ws_bill_customer_sk = tc.c_customer_sk)
     LIMIT 1) AS preferred_warehouse
FROM 
    TopCustomers tc, TotalSales ts
ORDER BY 
    tc.total_net_profit DESC;
