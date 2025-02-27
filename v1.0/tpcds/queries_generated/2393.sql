
WITH CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk AS returning_customer,
        SUM(wr.return_amount) AS total_return_amount,
        COUNT(wr.order_number) AS return_count,
        AVG(wr.return_quantity) AS avg_return_quantity
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
WarehouseInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
TopItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    CONCAT('Customer ID: ', hvc.c_customer_id, 
           ', Gender: ', hvc.cd_gender, 
           ', Marital Status: ', hvc.cd_marital_status, 
           ', Total Returns: ', COALESCE(cr.return_count, 0), 
           ', Total Return Amount: $', COALESCE(cr.total_return_amount, 0), 
           ', Avg Return Quantity: ', COALESCE(cr.avg_return_quantity, 0), 
           ', Item Stock: ', COALESCE(inv.total_stock, 0), 
           ', Warehouse Count: ', COALESCE(inv.warehouse_count, 0), 
           ', Total Sales: $', COALESCE(ti.total_sales, 0)) AS customer_summary
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerReturns cr ON hvc.c_customer_id = cr.returning_customer
LEFT JOIN 
    WarehouseInventory inv ON inv.inv_item_sk IN (SELECT ws_item_sk FROM TopItems WHERE sales_rank <= 10)
LEFT JOIN 
    TopItems ti ON ti.ws_item_sk = inv.inv_item_sk
WHERE 
    hvc.cd_income_band_sk IS NOT NULL
ORDER BY 
    cr.total_return_amount DESC NULLS LAST;
