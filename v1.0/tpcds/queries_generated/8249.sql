
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_id,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returned,
        cr.total_return_amount,
        cr.return_count
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.customer_id = c.c_customer_sk
    WHERE 
        cr.total_returned > 10 -- Considering customers who returned more than 10 items
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerPerformance AS (
    SELECT 
        hrc.c_customer_id,
        sd.total_sales,
        sd.order_count,
        sd.total_profit,
        hrc.total_returned,
        hrc.total_return_amount,
        hrc.return_count
    FROM 
        HighReturnCustomers hrc
    LEFT JOIN 
        SalesData sd ON hrc.c_customer_id = sd.customer_id
)
SELECT 
    c.c_customer_id,
    COALESCE(cp.total_sales, 0) AS total_sales,
    COALESCE(cp.order_count, 0) AS order_count,
    COALESCE(cp.total_profit, 0) AS total_profit,
    cp.total_returned,
    cp.total_return_amount,
    cp.return_count,
    (COALESCE(cp.total_sales, 0) - COALESCE(cp.total_return_amount, 0)) AS net_revenue,
    (SELECT 
        COUNT(*) 
     FROM 
        store_sales ss 
     WHERE 
        ss_customer_sk = c.c_customer_sk) AS store_sales_count
FROM 
    customer c
LEFT JOIN 
    CustomerPerformance cp ON c.c_customer_id = cp.c_customer_id
WHERE 
    c.c_preferred_cust_flag = 'Y'
ORDER BY 
    net_revenue DESC
LIMIT 50;
