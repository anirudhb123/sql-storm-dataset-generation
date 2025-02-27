
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_store_returns,
        COUNT(cr.cr_order_number) AS total_catalog_returns,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(sr.sr_return_amt, 0)) + SUM(COALESCE(cr.cr_return_amount, 0)) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_store_returns,
        cs.total_catalog_returns,
        cs.total_store_return_amount,
        cs.total_catalog_return_amount
    FROM 
        CustomerReturnStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.customer_rank <= 10
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_web_sales_profit,
        SUM(cs.cs_net_profit) AS total_catalog_sales_profit,
        SUM(ss.ss_net_profit) AS total_store_sales_profit
    FROM 
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ss.d_year,
    ss.total_web_sales_profit,
    ss.total_catalog_sales_profit,
    ss.total_store_sales_profit
FROM 
    TopCustomers tc
JOIN 
    SalesSummary ss ON 1=1 -- Cross join to associate top customers with every year in the sales summary
ORDER BY 
    total_web_sales_profit DESC, 
    total_catalog_sales_profit DESC, 
    total_store_sales_profit DESC;
