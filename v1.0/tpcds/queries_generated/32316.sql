
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name, 
        s_number_employees,
        s_floor_space,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY s_store_name) AS level
    FROM 
        store 
    WHERE 
        s_number_employees IS NOT NULL
    UNION ALL
    SELECT 
        s_store_sk,
        s_store_name, 
        s_number_employees,
        s_floor_space,
        level + 1
    FROM 
        sales_hierarchy
    WHERE 
        s_floor_space > (
            SELECT 
                AVG(s_floor_space) 
            FROM 
                store 
            WHERE 
                s_closed_date_sk IS NULL
        )
),
item_sales_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        i.i_category
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        i.i_item_sk, i.i_category
),
customer_rating AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_credit_rating
),
final_report AS (
    SELECT 
        sh.s_store_name,
        iss.total_quantity_sold,
        iss.avg_sales_price,
        cr.cd_credit_rating,
        cr.total_orders AS customer_orders
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        item_sales_summary iss ON sh.s_store_sk = iss.i_item_sk 
    LEFT JOIN 
        customer_rating cr ON cr.total_orders > 5
)
SELECT 
    f.s_store_name,
    f.total_quantity_sold,
    f.avg_sales_price,
    f.cd_credit_rating,
    COALESCE(f.customer_orders, 0) AS customer_order_count
FROM 
    final_report f
WHERE 
    f.total_quantity_sold IS NOT NULL
ORDER BY 
    f.total_quantity_sold DESC
FETCH FIRST 10 ROWS ONLY;
