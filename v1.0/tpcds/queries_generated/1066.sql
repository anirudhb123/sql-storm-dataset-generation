
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') 
                           AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        wr_wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        cr.customer_sk,
        cr.total_return_amount,
        cr.total_returns,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM 
        CustomerReturns cr
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_net_profit,
    COALESCE(trc.total_return_amount, 0) AS total_return_amount,
    COALESCE(trc.total_returns, 0) AS total_returns,
    (sd.total_sales - COALESCE(trc.total_return_amount, 0)) AS net_sales
FROM 
    SalesData sd
LEFT JOIN 
    TopReturningCustomers trc ON sd.web_site_id = trc.customer_sk
WHERE 
    sd.sales_rank <= 10
ORDER BY 
    net_sales DESC
LIMIT 20;
