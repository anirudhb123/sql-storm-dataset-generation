
WITH RECURSIVE SalesGrowth AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING SUM(ws_net_paid) > (SELECT AVG(total_spent) FROM (SELECT SUM(ws_net_paid) AS total_spent 
                                                           FROM web_sales GROUP BY ws_bill_customer_sk) AS sub)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    sg.d_year,
    sg.total_profit,
    COUNT(DISTINCT cr.wr_order_number) AS total_returns,
    CASE 
        WHEN sg.total_profit IS NULL THEN 'No Sales' 
        ELSE ROUND((tc.total_spent - COALESCE(cr.total_return_amt, 0)) / NULLIF(tc.total_spent, 0) * 100, 2) 
    END AS profit_margin_percentage
FROM 
    TopCustomers tc
LEFT JOIN SalesGrowth sg ON sg.rank = 1
LEFT JOIN CustomerReturns cr ON tc.c_customer_id = cr.wr_returning_customer_sk
GROUP BY tc.c_customer_id, tc.c_first_name, tc.c_last_name, sg.d_year, sg.total_profit
ORDER BY sg.d_year DESC, profit_margin_percentage DESC;
