
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),

top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.d_year
    WHERE 
        ci.gender_rank <= 10
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    CASE 
        WHEN tc.sales_rank <= 5 THEN 'Top Spender'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    top_customers tc
LEFT JOIN 
    warehouse w ON w.w_warehouse_sk = (
        SELECT 
            w_warehouse_sk 
        FROM 
            inventory 
        WHERE 
            inv_item_sk IN (
                SELECT 
                    ws.ws_item_sk 
                FROM 
                    web_sales ws 
                WHERE 
                    ws.ws_bill_customer_sk = tc.c_customer_sk
            ) 
        LIMIT 1
    )
WHERE 
    w.w_warehouse_sk IS NOT NULL
ORDER BY 
    total_sales DESC;
