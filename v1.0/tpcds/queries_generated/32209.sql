
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs_bill_customer_sk,
        cs_order_number,
        cs_quantity,
        cs_ext_sales_price,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_bill_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        sr_customer_sk,
        sr_ticket_number,
        sr_return_quantity,
        sr_return_amt,
        sh.level + 1
    FROM 
        store_returns sr
    JOIN 
        SalesHierarchy sh ON sr_ticket_number = sh.cs_order_number
    WHERE 
        sr_customer_sk IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sh.cs_quantity, 0)) AS total_sales_quantity,
        SUM(COALESCE(sh.cs_ext_sales_price, 0)) AS total_sales_amount,
        COUNT(DISTINCT sh.cs_order_number) AS total_orders,
        AVG(sh.cs_ext_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        SalesHierarchy sh ON c.c_customer_sk = sh.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales_quantity,
        cs.total_sales_amount,
        cs.total_orders,
        cs.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales_amount DESC) AS rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON c.c_customer_id = cs.c_customer_id
    WHERE 
        cs.total_sales_amount > (SELECT AVG(total_sales_amount) FROM CustomerStats)
)
SELECT 
    tc.c_customer_id,
    tc.total_sales_quantity,
    tc.total_sales_amount,
    tc.total_orders,
    tc.avg_order_value,
    d.d_year,
    sm.sm_type,
    w.w_warehouse_name,
    IFNULL(d.d_holiday, 'N') AS holiday_flag
FROM 
    TopCustomers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT MAX(sm_ship_mode_sk) FROM ship_mode)
JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT MAX(w_warehouse_sk) FROM warehouse)
WHERE 
    tc.rank <= 10 
ORDER BY 
    tc.total_sales_amount DESC;
