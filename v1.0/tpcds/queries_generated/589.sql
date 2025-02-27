
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        sr_customer_sk
),
WebSalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_qty,
        SUM(ws_net_paid_inc_tax) AS total_web_amt
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_bill_customer_sk
),
TotalSales AS (
    SELECT 
        COALESCE(c.c_customer_sk, w.ws_bill_customer_sk) AS customer_sk,
        COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown Customer') AS customer_name,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ws.total_web_qty, 0) AS total_web_qty,
        COALESCE(ws.total_web_amt, 0) AS total_web_amt
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    FULL OUTER JOIN 
        WebSalesDetails ws ON c.c_customer_sk = ws.ws_bill_customer_sk
),
AggregatedSales AS (
    SELECT 
        customer_sk,
        customer_name,
        total_return_qty,
        total_return_amt,
        total_web_qty,
        total_web_amt,
        (total_return_amt - total_web_amt) / NULLIF(total_web_amt, 0) AS return_to_sales_ratio
    FROM 
        TotalSales
)
SELECT 
    customer_sk,
    customer_name,
    total_return_qty,
    total_return_amt,
    total_web_qty,
    total_web_amt,
    return_to_sales_ratio,
    RANK() OVER (ORDER BY return_to_sales_ratio DESC) AS return_rank
FROM 
    AggregatedSales
WHERE 
    return_to_sales_ratio IS NOT NULL
AND 
    total_web_qty > 0
ORDER BY 
    return_rank
LIMIT 10;
