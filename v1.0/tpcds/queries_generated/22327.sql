
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date AS first_purchase_date,
        d.d_year AS purchase_year,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        CASE 
            WHEN COUNT(DISTINCT ws.ws_order_number) > 10 THEN 'Frequent'
            WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High Spender'
            ELSE 'Casual'
        END AS customer_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date, d.d_year, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.first_purchase_date,
        c.purchase_year,
        c.cd_gender,
        c.cd_marital_status,
        c.total_orders,
        c.total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.purchase_year ORDER BY c.total_spent DESC) AS rank
    FROM 
        customer_info c
),
warehouse_data AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name
),
returns_summary AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
bizarre_results AS (
    SELECT 
        tc.c_first_name || ' ' || tc.c_last_name AS full_name,
        tc.customer_category,
        wd.w_warehouse_name,
        wd.total_inventory,
        COALESCE(rs.total_returns, 0) AS total_returns,
        CASE 
            WHEN wd.total_inventory IS NULL THEN 'Unknown'
            ELSE CASE 
                WHEN wd.total_inventory > 1000 THEN 'Adequate'
                ELSE 'Low Stock'
            END 
        END AS inventory_status
    FROM 
        top_customers tc
    LEFT JOIN 
        warehouse_data wd ON wd.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w ORDER BY RANDOM() LIMIT 1)
    LEFT JOIN 
        returns_summary rs ON rs.sr_store_sk = (SELECT sr.sr_store_sk FROM store_returns sr ORDER BY RANDOM() LIMIT 1)
    WHERE 
        tc.rank <= 5
)
SELECT 
    *,
    CASE 
        WHEN total_spent IS NULL THEN 'No Spending'
        ELSE 'Regular Customer'
    END AS overall_status
FROM 
    bizarre_results
ORDER BY 
    total_spent DESC, full_name;
