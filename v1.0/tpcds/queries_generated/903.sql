
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        c.total_sales,
        c.order_count,
        c.avg_order_value,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(NULLIF(tc.avg_order_value, 0), 'N/A') AS avg_order_value,
    w.w_warehouse_name,
    r.r_reason_desc
FROM 
    TopCustomers tc
LEFT JOIN 
    store_returns sr ON tc.customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN 
    warehouse w ON w.w_warehouse_sk = (
        SELECT 
            inv.inv_warehouse_sk
        FROM 
            inventory inv
        JOIN 
            store s ON s.s_store_sk = sr.s_store_sk
        WHERE 
            inv.inv_item_sk = sr.sr_item_sk
        LIMIT 1
    )
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
