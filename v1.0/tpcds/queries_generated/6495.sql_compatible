
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),

warehouse_info AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)

SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    ss.order_count,
    ss.last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound,
    wi.w_warehouse_name,
    wi.total_inventory
FROM 
    sales_summary ss
JOIN 
    customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
JOIN 
    warehouse_info wi ON wi.w_warehouse_sk = (
        SELECT inv.inv_warehouse_sk 
        FROM inventory inv 
        JOIN web_sales ws ON inv.inv_item_sk = ws.ws_item_sk 
        WHERE ws.ws_bill_customer_sk = ss.c_customer_sk 
        FETCH FIRST 1 ROW ONLY
    )
ORDER BY 
    ss.total_sales DESC
FETCH FIRST 50 ROWS ONLY;
