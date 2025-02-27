
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS average_price,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws.web_site_sk
),
customer_with_returns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        customer c 
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM 
        customer c 
    LEFT JOIN 
        customer_with_returns r ON c.c_customer_sk = r.c_customer_sk
    ORDER BY 
        r.total_return_amount DESC
    LIMIT 10
)
SELECT 
    ss.web_site_sk,
    ss.total_quantity,
    ss.total_profit,
    ss.average_price,
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.return_count,
    tc.total_return_amount
FROM 
    sales_summary ss
JOIN 
    top_customers tc ON ss.web_site_sk IS NOT NULL
WHERE 
    ss.total_profit > (SELECT AVG(total_profit) FROM sales_summary) 
    AND ss.total_quantity > (
        SELECT AVG(total_quantity) 
        FROM sales_summary 
        WHERE total_quantity IS NOT NULL
    )
ORDER BY 
    ss.average_price DESC
LIMIT 20;
