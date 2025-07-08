
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ss_store_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_store_sales,
        cs.total_web_sales,
        (cs.total_store_sales + cs.total_web_sales) AS combined_sales
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_store_sales + cs.total_web_sales > 10000
),
completed_returns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    s.sales_rank,
    hvc.c_customer_sk,
    hvc.combined_sales,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount
FROM 
    sales_summary s
JOIN 
    high_value_customers hvc ON s.ss_store_sk = (SELECT ss_store_sk FROM store WHERE s_store_sk = ss_store_sk)
LEFT JOIN 
    completed_returns cr ON hvc.c_customer_sk = cr.wr_returning_customer_sk
WHERE 
    hvc.combined_sales > 15000 OR cr.total_return_amt > 500
ORDER BY 
    s.sales_rank, hvc.combined_sales DESC;
