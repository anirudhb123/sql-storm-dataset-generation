
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
SalesRanked AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders
    FROM 
        SalesRanked cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    t.c_customer_id,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.total_orders,
    COALESCE(su.avg_sales_per_order, 0) AS avg_sales_per_order,
    CASE 
        WHEN t.total_orders > 0 THEN t.total_sales / t.total_orders 
        ELSE 0 
    END AS avg_order_value
FROM 
    TopCustomers t
LEFT JOIN 
    (
        SELECT 
            ws_bill_customer_sk,
            AVG(ws_ext_sales_price) AS avg_sales_per_order
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) su ON t.c_customer_id = su.ws_bill_customer_sk;
