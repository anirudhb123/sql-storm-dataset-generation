
WITH sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ss_store_sk
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_purchases,
        SUM(ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c_customer_sk, cd_gender, cd_marital_status, cd_income_band_sk
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    s.store_id,
    s.total_quantity,
    s.total_net_paid,
    c.cd_gender,
    c.total_purchases,
    c.total_spent,
    w.w_warehouse_name,
    w.total_inventory
FROM 
    sales_summary s
JOIN 
    customer_summary c ON s.ss_store_sk = c.c_customer_sk
JOIN 
    warehouse_summary w ON s.ss_store_sk = w.w_warehouse_sk
ORDER BY 
    s.total_net_paid DESC, c.total_spent DESC
LIMIT 10;
