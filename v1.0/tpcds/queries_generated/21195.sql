
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_return_quantity,
        cr_return_amt,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_return_quantity DESC) AS ReturnRank
    FROM 
        catalog_returns
    WHERE 
        cr_return_qty IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        SUM(cd_dep_count) AS TotalDependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(i.inv_quantity_on_hand) AS TotalInventory,
        COUNT(DISTINCT s.s_store_id) AS StoreCount
    FROM 
        warehouse w
    JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN 
        store s ON s.s_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
CustomerFunnel AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws_order_number) AS OrdersPlaced,
        SUM(ws_sales_price) AS TotalSpent,
        CASE 
            WHEN SUM(ws_sales_price) IS NULL THEN 'No Sales'
            WHEN SUM(ws_sales_price) >= 1000 THEN 'High Value'
            WHEN SUM(ws_sales_price) BETWEEN 500 AND 999 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS ValueCategory
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
MaxReturnCustomer AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS TotalReturnedQuantity
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
    HAVING 
        SUM(cr_return_quantity) > 10
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.TotalDependents,
    COALESCE(rr.ReturnRank, '0') AS ReturnRank,
    cs.OrdersPlaced, 
    cs.TotalSpent, 
    cs.ValueCategory,
    ws.TotalInventory,
    ws.StoreCount
FROM 
    customer c
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RankedReturns rr ON rr.cr_returning_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerFunnel cs ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    WarehouseStats ws ON ws.w_warehouse_id = (SELECT MAX(w_warehouse_id) FROM warehouse)
WHERE 
    (c.c_birth_month = 1 AND c.c_birth_day IS NOT NULL OR c.c_birth_year IS NULL)
AND 
    (cs.OrdersPlaced > 0 OR rr.ReturnRank IS NOT NULL)
ORDER BY 
    cs.TotalSpent DESC;
