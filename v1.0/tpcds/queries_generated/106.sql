
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cs.sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
recent_dates AS (
    SELECT 
        MAX(d.d_date) AS most_recent_date
    FROM 
        date_dim d
    WHERE 
        d.d_current_day = 'Y'
),
inventory_level AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.total_sales,
    td.most_recent_date,
    COALESCE(SUM(il.total_inventory), 0) AS inventory_on_hand
FROM 
    top_customers tc
CROSS JOIN 
    recent_dates td
LEFT JOIN 
    inventory_level il ON il.inv_item_sk IN (
        SELECT ws.ws_item_sk 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
    )
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.total_sales, td.most_recent_date
ORDER BY 
    total_sales DESC;
