
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt, 
        COUNT(*) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cr.total_return_amt,
        cr.total_returns,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS rn
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_return_amt IS NOT NULL
),
ItemSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is.total_quantity_sold,
        RANK() OVER (ORDER BY is.total_quantity_sold DESC) AS item_rank
    FROM 
        item i
    JOIN 
        ItemSales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity_sold,
    CASE 
        WHEN tc.total_returns > 5 THEN 'High Return Customer'
        ELSE 'Normal Customer'
    END AS customer_category
FROM 
    TopCustomers tc
CROSS JOIN 
    TopItems ti
WHERE 
    tc.rn <= 10 
    AND (ti.item_rank <= 10 OR ti.total_quantity_sold > 100)
ORDER BY 
    tc.total_return_amt DESC, 
    ti.total_quantity_sold DESC;
