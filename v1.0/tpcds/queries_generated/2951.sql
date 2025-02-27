
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returns,
        cr.total_return_value,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_value DESC) AS rn
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_returns,
    tc.total_return_value,
    d.d_date AS return_date,
    w.w_warehouse_name,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS returned_items
FROM 
    TopCustomers tc
INNER JOIN 
    store_returns sr ON sr.sr_customer_sk = tc.sr_customer_sk
INNER JOIN 
    item i ON i.i_item_sk = sr.sr_item_sk
INNER JOIN 
    warehouse w ON w.w_warehouse_sk = sr.sr_store_sk
INNER JOIN 
    date_dim d ON d.d_date_sk = sr.sr_returned_date_sk
WHERE 
    tc.rn <= 10
GROUP BY 
    tc.c_customer_id, 
    tc.total_returns, 
    tc.total_return_value, 
    d.d_date, 
    w.w_warehouse_name
HAVING 
    SUM(sr_return_amt_inc_tax) > 1000
ORDER BY 
    tc.total_return_value DESC;
