
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.*,
        cs.total_orders,
        cs.total_profit,
        cs.avg_sales_price
    FROM 
        CustomerStats AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_orders > 5
),
WarehouseDetails AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        warehouse AS w
    JOIN 
        web_sales AS ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
    HAVING 
        SUM(ws.ws_net_paid) > 100000
),
SalesComparison AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_qty) AS total_sold,
        SUM(cs.cs_sales_price) AS catalog_sales_price
    FROM 
        web_sales AS ws
    LEFT JOIN 
        catalog_sales AS cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tw.w_warehouse_name,
    tw.total_revenue,
    sc.total_sold,
    COALESCE(sc.catalog_sales_price, 0) AS catalog_sales_price,
    (tc.total_profit - COALESCE(sc.catalog_sales_price, 0)) AS profit_after_sales
FROM 
    TopCustomers AS tc
FULL OUTER JOIN 
    WarehouseDetails AS tw ON tc.total_orders > 10  -- potentially introduce rows for the comparison
FULL OUTER JOIN 
    SalesComparison AS sc ON tc.total_orders > 5  -- conditions for filtering
WHERE 
    (tw.total_revenue IS NOT NULL OR sc.total_sold IS NOT NULL)
ORDER BY 
    tc.total_profit DESC, 
    tw.total_revenue DESC;
