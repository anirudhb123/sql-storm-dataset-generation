
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
    WHERE 
        total_orders > 5
),
LatestDate AS (
    SELECT d_date_sk 
    FROM date_dim 
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    dd.d_month_seq,
    dd.d_year,
    w.w_warehouse_name,
    sm.sm_type
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    LatestDate ld ON ws.ws_sold_date_sk = ld.d_date_sk
JOIN 
    date_dim dd ON ld.d_date_sk = dd.d_date_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    total_sales DESC, total_orders DESC;
