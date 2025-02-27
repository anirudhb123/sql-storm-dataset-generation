
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
top_sales AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        rank <= 5
),
customers_with_returns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(cwr.total_returns, 0) AS total_returns
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customers_with_returns cwr ON c.c_customer_sk = cwr.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cwr.total_returns
    HAVING 
        SUM(ws.ws_sales_price) > 1000
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    tc.c_customer_sk,
    tc.total_sales AS customer_sales,
    tc.total_returns
FROM 
    top_sales ts
JOIN 
    top_customers tc ON ts.total_sales > tc.total_sales
ORDER BY 
    ts.total_sales DESC, tc.total_sales DESC;
