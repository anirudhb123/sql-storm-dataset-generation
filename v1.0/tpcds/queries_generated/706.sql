
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
customer_returns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.wr_return_amt) AS total_web_returns,
        COUNT(cr.wr_order_number) AS return_count
    FROM web_returns cr
    GROUP BY cr.returning_customer_sk
),
net_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) - COALESCE(cr.total_web_returns, 0) AS net_sales
    FROM customer_sales cs
    LEFT JOIN customer_returns cr ON cs.c_customer_sk = cr.returning_customer_sk
)
SELECT 
    ns.c_customer_sk,
    ns.c_first_name,
    ns.c_last_name,
    ns.net_sales,
    RANK() OVER (ORDER BY ns.net_sales DESC) AS sales_rank,
    CASE 
        WHEN ns.net_sales > 1000 THEN 'High Value'
        WHEN ns.net_sales > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM net_sales ns
WHERE ns.net_sales IS NOT NULL
ORDER BY ns.net_sales DESC
LIMIT 10;

-- Including an outer join with aggregate functions on a domain over time considering different ship modes
SELECT 
    d.d_date AS transaction_date,
    sm.sm_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_year = 2023 AND d.d_dow = 1 -- considering only Mondays
GROUP BY d.d_date, sm.sm_type
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY transaction_date, total_sales DESC;
