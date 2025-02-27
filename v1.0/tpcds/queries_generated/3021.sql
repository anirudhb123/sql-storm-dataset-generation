
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amt) AS total_returned_amount,
        COUNT(DISTINCT cr.order_number) AS total_return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_qty,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amt,
        DENSE_RANK() OVER (ORDER BY COALESCE(cr.total_returned_amount, 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
    WHERE 
        (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
        AND (cd.cd_marital_status IS NOT NULL AND cd.cd_marital_status IN ('M', 'S'))
),
WarehouseStatistics AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        AVG(ss.net_profit) AS avg_net_profit,
        COUNT(*) AS total_sales
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returned_qty,
    tc.total_returned_amt,
    ws.w_warehouse_name,
    ws.avg_net_profit,
    ws.total_sales
FROM 
    TopCustomers tc
JOIN 
    WarehouseStatistics ws ON ws.total_sales > 100
WHERE 
    tc.rank <= 10 
ORDER BY 
    tc.total_returned_amt DESC;
