
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
daily_sales AS (
    SELECT 
        dd.d_date AS sales_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        dd.d_date
),
top_sales AS (
    SELECT 
        customer_id,
        customer_name,
        total_sales
    FROM 
        sales_hierarchy
    WHERE 
        sales_rank <= 5
)
SELECT 
    ds.sales_date,
    COALESCE(ts.customer_name, 'No Sales') AS top_customer,
    COALESCE(ts.total_sales, 0) AS top_customer_sales,
    ds.daily_sales,
    ds.total_orders,
    ds.unique_customers
FROM 
    daily_sales ds
LEFT JOIN 
    top_sales ts ON ds.sales_date = (SELECT 
                                        MAX(dd.d_date) 
                                     FROM 
                                        date_dim dd 
                                     WHERE 
                                        dd.d_date_sk IN (SELECT 
                                                            ws_sold_date_sk 
                                                        FROM 
                                                            web_sales 
                                                        WHERE 
                                                            ws_ext_sales_price = ds.daily_sales
                                                        GROUP BY 
                                                            ws_sold_date_sk))
ORDER BY 
    ds.sales_date DESC;
