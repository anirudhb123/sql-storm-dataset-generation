
WITH RECURSIVE sales_trend AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
expanded_sales AS (
    SELECT 
        d_year,
        total_profit,
        LAG(total_profit, 1) OVER (ORDER BY d_year) AS previous_year_profit,
        COALESCE(total_profit - LAG(total_profit, 1) OVER (ORDER BY d_year), total_profit) AS profit_change
    FROM 
        sales_trend
),
customer_return_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    e.d_year,
    e.total_profit,
    e.previous_year_profit,
    e.profit_change,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(cr.total_return_qty, 0) AS total_return_qty
FROM 
    expanded_sales e
LEFT JOIN 
    customer_return_summary cr ON e.d_year = (SELECT d_year FROM date_dim WHERE d_date_sk = cr.wr_returned_date_sk)
WHERE 
    e.rank <= 10
ORDER BY 
    e.d_year ASC;
