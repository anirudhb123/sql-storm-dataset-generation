
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
customer_returns AS (
    SELECT 
        sr_returning_customer_sk AS customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return,
        COUNT(*) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        sr_returning_customer_sk
),
sales_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(S.ws_net_profit), 0) AS total_sales,
        COALESCE(cr.total_return, 0) AS total_returns,
        COUNT(S.ws_order_number) AS total_orders,
        AVG(S.ws_net_profit) AS avg_order_value,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(S.ws_net_profit), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales S ON c.c_customer_sk = S.ws_bill_customer_sk
    LEFT JOIN 
        customer_returns cr ON cr.customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_sales > 1000 OR total_returns > 50
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    ss.total_returns,
    ss.total_orders,
    ss.avg_order_value,
    CASE 
        WHEN ss.sales_rank < 11 THEN 'Top 10% Customers'
        ELSE 'Regular Customers'
    END AS customer_rank
FROM 
    sales_summary ss
ORDER BY 
    ss.total_sales DESC
LIMIT 50;

