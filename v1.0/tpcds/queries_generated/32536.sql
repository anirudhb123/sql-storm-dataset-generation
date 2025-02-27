
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        ss.ss_sales_price,
        ss.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_sales_price DESC) AS profit_rank
    FROM 
        store s
    INNER JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2)
),
customer_returns AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.returning_customer_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_returns cr ON c.c_customer_sk = cr.returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cr.total_returned_amount
)
SELECT 
    ss.s_store_name,
    ss.ss_sales_price,
    sh.total_orders,
    sh.total_profit,
    sh.total_returned_amount,
    CASE 
        WHEN sh.total_profit > 1000 THEN 'HIGH'
        WHEN sh.total_profit BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM 
    sales_hierarchy sh
JOIN 
    sales_summary ss ON sh.s_store_sk = ss.c_customer_sk
WHERE 
    ss.total_orders > 5
ORDER BY 
    sh.total_profit DESC, 
    ss.total_returned_amount ASC;
