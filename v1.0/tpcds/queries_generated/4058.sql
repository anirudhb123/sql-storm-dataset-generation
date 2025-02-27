
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2022 AND d_moy IN (6, 7)  -- June and July of 2022
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.num_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > (
            SELECT AVG(total_sales)
            FROM CustomerSales
        )
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.num_orders,
    w.w_warehouse_name,
    COALESCE(i.inv_quantity_on_hand, 0) AS quantity_available,
    r.r_reason_desc AS return_reason
FROM 
    TopCustomers t
LEFT JOIN 
    store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
LEFT JOIN 
    inventory i ON ss.ss_item_sk = i.inv_item_sk AND i.inv_date_sk = (
        SELECT MAX(inv.inv_date_sk)
        FROM inventory inv
        WHERE 
            inv.inv_item_sk = ss.ss_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
    )
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = t.c_customer_sk 
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
