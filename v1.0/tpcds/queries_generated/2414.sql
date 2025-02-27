
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        TopCustomers AS c
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    rc.order_count,
    cr.total_returned_quantity,
    cr.total_return_amount,
    CASE 
        WHEN cr.total_returns IS NULL 
        THEN 'No Returns' 
        ELSE 'Has Returns' 
    END AS return_status
FROM 
    RankedCustomers AS rc
LEFT JOIN 
    CustomerReturns AS cr ON rc.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.total_spent DESC;
