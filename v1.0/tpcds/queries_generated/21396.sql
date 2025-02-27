
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_qty) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returned_qty,
        cr.total_returned_amt
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cr.total_returned_qty IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales_amt,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    COALESCE(sd.total_sales_amt, 0) AS total_sales_amt,
    COALESCE(sd.order_count, 0) AS order_count,
    CASE 
        WHEN tc.total_returned_amt > 0 THEN (tc.total_returned_amt / NULLIF(sd.total_sales_amt, 0))
        ELSE NULL
    END AS return_to_sales_ratio
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.s_customer_sk = sd.customer_sk
ORDER BY 
    return_to_sales_ratio DESC NULLS LAST
LIMIT 10;

SELECT 
    COUNT(*) AS distinct_customer_count
FROM 
    store_sales ss
WHERE 
    ss.ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2)
    AND ss.ss_quantity > ALL
        (SELECT AVG(ss3.ss_quantity) FROM store_sales ss3)
    AND ss.ss_item_sk IN 
        (SELECT DISTINCT sr_item_sk FROM store_returns)
UNION 
SELECT 
    COUNT(*) AS store_count
FROM 
    store
WHERE 
    s_closed_date_sk IS NULL;

