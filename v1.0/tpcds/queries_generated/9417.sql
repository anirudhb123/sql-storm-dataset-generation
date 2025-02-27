
WITH CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS average_spending
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
DepartmentSales AS (
    SELECT 
        cp.cp_department,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        catalog_page cp
    JOIN 
        web_sales ws ON ws.ws_item_sk IN (SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_catalog_page_sk = cp.cp_catalog_page_sk)
    GROUP BY 
        cp.cp_department
), 
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    ds.cp_department,
    ws.w_warehouse_id,
    cs.customer_count,
    cs.total_profit AS customer_profit,
    cs.average_spending,
    ds.total_quantity,
    ds.total_sales,
    wp.total_profit AS warehouse_profit,
    wp.total_orders
FROM 
    CustomerStats cs
JOIN 
    DepartmentSales ds ON cs.customer_count > 100
JOIN 
    WarehousePerformance wp ON wp.total_profit > 10000
ORDER BY 
    customer_profit DESC, warehouse_profit DESC;
