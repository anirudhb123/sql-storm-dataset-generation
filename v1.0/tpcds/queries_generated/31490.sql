
WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(sd.ws_net_paid) AS total_spent,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.total_spent,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_summary cs
),
customer_orders AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS order_count,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_paid
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
warehouse_inventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk, inv.inv_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_category
),
final_report AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent,
        ti.i_item_desc,
        ti.total_quantity_sold,
        ti.total_net_profit,
        wi.total_quantity AS warehouse_quantity,
        CASE 
            WHEN tc.rank <= 10 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        top_customers tc
    LEFT JOIN 
        item_summary ti ON ti.total_quantity_sold > 1000
    LEFT JOIN 
        warehouse_inventory wi ON wi.inv_item_sk = ti.i_item_sk
)
SELECT 
    *,
    CONCAT(first_name, ' ', last_name) AS full_name,
    CASE
        WHEN warehouse_quantity IS NULL THEN 'Out of Stock'
        WHEN warehouse_quantity < 100 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    final_report
ORDER BY 
    total_spent DESC
LIMIT 50;
