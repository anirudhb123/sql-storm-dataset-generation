
WITH sales_summary AS (
    SELECT 
        cd.gender AS customer_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        d.d_year AS sales_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        cd.gender, d.d_year
),
average_sales AS (
    SELECT 
        customer_gender,
        AVG(total_sales) AS average_sales
    FROM 
        sales_summary
    GROUP BY 
        customer_gender
),
top_sales AS (
    SELECT 
        customer_gender,
        total_sales,
        sales_year
    FROM 
        sales_summary
    WHERE 
        total_sales = (SELECT MAX(total_sales) FROM sales_summary)
)
SELECT 
    a.customer_gender,
    a.average_sales,
    b.total_sales AS top_total_sales,
    b.sales_year AS top_sales_year
FROM 
    average_sales a
JOIN 
    top_sales b ON a.customer_gender = b.customer_gender
ORDER BY 
    a.average_sales DESC;
