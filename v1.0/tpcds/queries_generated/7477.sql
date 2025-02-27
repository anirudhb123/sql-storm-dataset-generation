
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        MAX(ss.ss_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.total_sales,
        s.total_transactions,
        s.last_purchase_date
    FROM 
        sales_summary s
    JOIN 
        customer c ON s.c_customer_id = c.c_customer_id
    ORDER BY 
        s.total_sales DESC
    LIMIT 10
)
SELECT 
    t.c_customer_id,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.total_transactions,
    t.last_purchase_date,
    wd.warehouse_name,
    sm.sm_carrier,
    sd.d_date AS purchase_date
FROM 
    top_customers t
JOIN 
    web_sales ws ON t.c_customer_id = ws.ws_ship_customer_sk
JOIN 
    warehouse wd ON ws.ws_warehouse_sk = wd.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
WHERE 
    sd.d_year = 2020
ORDER BY 
    t.total_sales DESC;
