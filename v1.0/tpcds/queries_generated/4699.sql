
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(cr.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_credit_rating = 'Excellent'
        AND (COALESCE(cr.total_returned_qty, 0) < 5 OR cr.total_returned_amt < 100)
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory AS inv
    GROUP BY 
        inv.inv_warehouse_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_value
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT 
    w.w_warehouse_id,
    hi.c_first_name,
    hi.c_last_name,
    SUM(sd.total_sales_quantity) AS total_sales,
    SUM(sd.total_sales_value) AS total_sales_value,
    wi.total_quantity_on_hand
FROM 
    WarehouseInventory AS wi
JOIN 
    HighValueCustomers AS hi ON hi.c_customer_sk IS NOT NULL
JOIN 
    SalesData AS sd ON hi.c_customer_sk = sd.ws_bill_customer_sk
JOIN 
    warehouse AS w ON wi.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    w.w_warehouse_id, hi.c_first_name, hi.c_last_name
HAVING 
    SUM(sd.total_sales_quantity) > 100
ORDER BY 
    total_sales_value DESC;
