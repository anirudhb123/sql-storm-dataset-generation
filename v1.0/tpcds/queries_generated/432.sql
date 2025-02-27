
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_payment,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_payment
    FROM 
        CustomerSales cs
    JOIN 
        (SELECT c_customer_sk, c_customer_id 
         FROM customer) c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS warehouse_total_sales
    FROM 
        warehouse w 
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    ROUND(tc.avg_payment, 2) AS avg_payment,
    wi.warehouse_name,
    wi.warehouse_total_sales,
    CASE 
        WHEN tc.total_sales > wi.warehouse_total_sales THEN 'Customer outsells Warehouse' 
        ELSE 'Warehouse outsells Customer' 
    END AS performance_comparison
FROM 
    TopCustomers tc
LEFT JOIN 
    WarehouseInfo wi ON tc.total_sales > 50000
ORDER BY 
    tc.total_sales DESC, wi.warehouse_total_sales ASC;
