
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_amount
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_net_profit,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSales
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
WarehouseSales AS (
    SELECT 
        ws.ws_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_warehouse_sk
)
SELECT 
    tc.c_customer_id,
    cs.total_net_profit,
    cs.total_orders,
    wi.inv_warehouse_sk,
    wi.total_quantity,
    ws.total_sales,
    wi.total_quantity * ws.total_sales AS warehouse_performance_metric
FROM 
    TopCustomers tc
JOIN 
    CustomerSales cs ON tc.c_customer_id = cs.c_customer_id
JOIN 
    WarehouseInventory wi ON wi.inv_warehouse_sk IN (
        SELECT DISTINCT ws.ws_warehouse_sk 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
    )
JOIN 
    WarehouseSales ws ON ws.ws_warehouse_sk = wi.inv_warehouse_sk
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    cs.total_net_profit DESC, 
    warehouse_performance_metric DESC;
