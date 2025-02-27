
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cs.cs_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 -- Year filter
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.c_customer_sk = c.c_customer_sk
    WHERE 
        rs.sales_rank <= 10 -- Top 10 customers by sales
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_id, tc.total_sales
HAVING 
    total_orders > 5 -- At least 5 orders
ORDER BY 
    total_sales DESC;
