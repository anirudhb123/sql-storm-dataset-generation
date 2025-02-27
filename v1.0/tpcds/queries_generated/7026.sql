
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_order_number) AS num_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM
        store_returns
    GROUP BY
        sr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rr.total_return_quantity,
        rr.total_return_amt,
        rr.num_returns
    FROM 
        RankedReturns rr
    JOIN 
        customer c ON rr.returning_customer_sk = c.c_customer_sk
    WHERE 
        rr.return_rank <= 100
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ss.d_year,
    ss.total_sales,
    ss.total_discount,
    ss.average_profit
FROM 
    TopCustomers tc
JOIN 
    SalesSummary ss ON tc.c_customer_id IS NOT NULL
ORDER BY 
    ss.total_sales DESC, tc.total_return_amt DESC;
