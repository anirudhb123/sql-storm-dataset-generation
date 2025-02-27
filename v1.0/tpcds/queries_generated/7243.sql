
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
Top_Customers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales,
        cs.number_of_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
    WHERE 
        cs.total_sales > 1000
),
Monthly_Sales AS (
    SELECT 
        DATE_FORMAT(DATE(d.d_date), '%Y-%m') AS sales_month,
        SUM(ws.ws_sales_price) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        sales_month
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.number_of_orders,
    ms.sales_month,
    ms.monthly_sales
FROM 
    Top_Customers tc
JOIN 
    Monthly_Sales ms ON ms.monthly_sales > 5000
ORDER BY 
    tc.sales_rank, ms.sales_month;
