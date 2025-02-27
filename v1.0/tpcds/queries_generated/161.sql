
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS dense_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS total_web_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    CASE 
        WHEN tc.dense_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS customer_rank
FROM 
    TopCustomers tc
WHERE 
    tc.dense_rank <= 10 OR tc.total_web_sales IS NOT NULL
ORDER BY 
    tc.total_web_sales DESC;

-- Additional performance metrics
SELECT 
    d.d_year,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_list_price) AS avg_list_price,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS yearly_rank
FROM 
    date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
WHERE 
    d.d_year >= 2021
GROUP BY 
    d.d_year
HAVING 
    SUM(ws.ws_net_profit) > 100000
ORDER BY 
    d.d_year;
