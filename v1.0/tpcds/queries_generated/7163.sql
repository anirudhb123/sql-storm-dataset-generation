
WITH sales_summary AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND s.s_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        s.s_store_name
),
inventory_summary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ss.s_store_name,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_sales_price,
    ss.total_transactions,
    is.total_stock
FROM 
    sales_summary ss
JOIN 
    inventory_summary is ON ss.s_store_name = is.w_warehouse_name
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
