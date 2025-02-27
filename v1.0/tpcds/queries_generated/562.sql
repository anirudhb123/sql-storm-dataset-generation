
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023
        )
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amount DESC) AS rn
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returns > 5
),
InventoryStats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023
        )
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns,
    tc.total_return_amount,
    is.total_quantity_on_hand,
    sd.total_quantity_sold,
    sd.total_sales,
    COALESCE(sd.avg_sales_price, 0) AS avg_sales_price,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_category
FROM 
    TopCustomers tc
LEFT JOIN 
    InventoryStats is ON tc.c_customer_sk = is.inv_item_sk
LEFT JOIN 
    SalesData sd ON tc.c_customer_sk = sd.ws_item_sk
WHERE 
    is.warehouse_count > 1
ORDER BY 
    tc.total_return_amount DESC;
