
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS spender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS warehouse_profit
    FROM 
        warehouse w 
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
TopSpendingCustomers AS (
    SELECT
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        w.warehouse_name,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats cs
    JOIN 
        WarehouseStats w ON cs.spender_rank <= 10 -- assuming we want top 10 per gender
    WHERE 
        cs.total_orders > 5
)
SELECT 
    customer_name,
    warehouse_name,
    total_spent
FROM 
    TopSpendingCustomers
WHERE 
    total_spent > 1000
ORDER BY 
    total_spent DESC;
