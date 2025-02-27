
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        warehouse AS w
    JOIN 
        store AS s ON w.w_warehouse_sk = s.s_store_sk
    JOIN 
        store_sales AS ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.total_net_profit,
        cs.total_transactions,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_net_profit DESC) AS rn
    FROM 
        CustomerStats AS cs
)
SELECT 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.total_net_profit,
    tw.total_sales,
    CASE 
        WHEN tc.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    TopCustomers AS tc
LEFT JOIN 
    WarehouseStats AS tw ON tw.w_warehouse_sk IN (SELECT DISTINCT ss.ss_item_sk FROM store_sales AS ss WHERE ss.ss_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.cd_gender, tc.total_net_profit DESC;
