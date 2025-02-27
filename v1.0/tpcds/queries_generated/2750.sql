
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    JOIN 
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE 
        wr.wr_returned_date_sk IN (SELECT DISTINCT sr_returned_date_sk FROM store_returns)
    GROUP BY 
        wr.wr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_returns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    t.web_site_id,
    r.total_profit,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.total_return,
    c.total_spent,
    (CASE 
        WHEN r.total_profit IS NULL THEN 'No Sales'
        WHEN c.total_return > r.total_profit THEN 'High Returns'
        ELSE 'Normal'
    END) AS sales_return_status
FROM 
    RankedSales r
LEFT JOIN 
    web_site t ON r.web_site_sk = t.web_site_sk
LEFT JOIN 
    TopCustomers c ON r.web_site_sk = c.c_customer_id
WHERE 
    r.profit_rank = 1
ORDER BY 
    r.total_profit DESC;
