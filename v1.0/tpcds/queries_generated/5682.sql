
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS average_order_value,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),

TopCustomers AS (
    SELECT 
        c.customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cs.total_sales, 
        cs.order_count, 
        cs.average_order_value
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_id = c.c_customer_id 
    WHERE 
        cs.sales_rank <= 10
)

SELECT 
    tc.customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.average_order_value,
    dc.d_year,
    dc.d_month_seq,
    SUM(ws.ws_sales_price) AS monthly_sales
FROM 
    TopCustomers AS tc
JOIN 
    date_dim AS dc ON dc.d_date_sk IN (
        SELECT 
            DISTINCT ws.ws_sold_date_sk 
        FROM 
            web_sales AS ws 
        WHERE 
            ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer AS c WHERE c.c_customer_id = tc.customer_id)
    )
GROUP BY 
    tc.customer_id, tc.c_first_name, tc.c_last_name, tc.total_sales, tc.order_count, tc.average_order_value, dc.d_year, dc.d_month_seq
ORDER BY 
    tc.total_sales DESC, dc.d_year, dc.d_month_seq;
