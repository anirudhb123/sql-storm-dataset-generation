
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(COALESCE(ss.ss_quantity, 0)) AS total_sales_quantity,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(COALESCE(ss.ss_net_paid, 0)) DESC) AS sales_rank
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        AVG(ss.ss_net_paid) AS average_item_sales
    FROM 
        warehouse AS w
    LEFT JOIN 
        inventory AS inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN 
        store_sales AS ss ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
SalesMetrics AS (
    SELECT 
        cs.c_customer_sk,
        ws.w_warehouse_id,
        cs.total_sales_quantity,
        cs.total_sales_amount,
        ws.total_inventory,
        ws.distinct_items,
        ws.average_item_sales
    FROM 
        CustomerSummary AS cs
    JOIN 
        WarehouseSummary AS ws ON cs.total_sales_quantity > 0
)
SELECT 
    sm.c_customer_sk,
    sm.w_warehouse_id,
    sm.total_sales_quantity,
    sm.total_sales_amount,
    sm.total_inventory,
    sm.distinct_items,
    sm.average_item_sales,
    CASE 
        WHEN sm.total_sales_amount > 1000 THEN 'High Value'
        WHEN sm.total_sales_amount BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    SalesMetrics AS sm
ORDER BY 
    sm.total_sales_amount DESC;
