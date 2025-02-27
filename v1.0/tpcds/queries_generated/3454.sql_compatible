
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > 1000
),
TopSales AS (
    SELECT 
        t.c_customer_sk,
        t.c_first_name,
        t.c_last_name,
        t.total_orders,
        t.total_spent
    FROM 
        SalesSummary t
    WHERE 
        t.spending_rank <= 10
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
HighSalesWarehouse AS (
    SELECT 
        warehouse_id,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        WarehouseInfo
    WHERE 
        total_sales > 50000
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    ts.total_orders,
    ts.total_spent,
    hsw.warehouse_id,
    hsw.total_sales
FROM 
    TopSales ts
LEFT JOIN 
    HighSalesWarehouse hsw ON ts.total_spent > 2000
ORDER BY 
    ts.total_spent DESC, hsw.total_sales DESC;
