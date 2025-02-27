
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
top_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE((SELECT SUM(sr.sr_return_quantity) 
               FROM store_returns sr 
               WHERE sr.sr_customer_sk = tc.c_customer_sk), 0) AS total_returns,
    COALESCE((SELECT SUM(wr.wr_return_quantity)
               FROM web_returns wr 
               WHERE wr.w_returning_customer_sk = tc.c_customer_sk), 0) AS total_web_returns,
    tc.total_sales - COALESCE((SELECT SUM(sr.sr_return_amt) 
                                FROM store_returns sr 
                                WHERE sr.sr_customer_sk = tc.c_customer_sk), 0) 
          - COALESCE((SELECT SUM(wr.wr_return_amt) 
                       FROM web_returns wr 
                       WHERE wr.w_returning_customer_sk = tc.c_customer_sk), 0) AS net_sales_after_returns
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
