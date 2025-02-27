
WITH CustomerReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
SalesSummary AS (
    SELECT 
        ws_ship_mode_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_ext_sales_price) AS total_sales_amt
    FROM 
        web_sales
    GROUP BY 
        ws_ship_mode_sk
),
WarehouseInventory AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_warehouse_sk
),
QualifiedDemographics AS (
    SELECT 
        cd_demo_sk,
        COUNT(*) AS demographic_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'M' AND 
        cd_marital_status = 'S'
    GROUP BY 
        cd_demo_sk
)

SELECT 
    w.warehouse_name,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_qty, 0) AS total_return_qty,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_sales_amt, 0) AS total_sales_amt,
    COALESCE(inv.total_inventory, 0) AS total_inventory,
    q.avg_purchase_estimate
FROM 
    warehouse w
LEFT JOIN 
    CustomerReturns cr ON w.w_warehouse_sk = cr.sr_store_sk
LEFT JOIN 
    SalesSummary ss ON ss.ws_ship_mode_sk = (
        SELECT 
            sm_ship_mode_sk 
        FROM 
            ship_mode 
        WHERE 
            sm_code = 'Standard_Delivery' 
        LIMIT 1
    )
LEFT JOIN 
    WarehouseInventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN 
    QualifiedDemographics q ON q.cd_demo_sk IN (
        SELECT 
            c_current_cdemo_sk 
        FROM 
            customer 
        WHERE 
            c_current_addr_sk IS NOT NULL
    )
WHERE 
    w.w_warehouse_sq_ft >= 10000
ORDER BY 
    w.warehouse_name;
