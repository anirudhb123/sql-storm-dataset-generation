
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_sales) AS avg_sales,
        AVG(cs.order_count) AS avg_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesRanks AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY avg_sales DESC) AS sales_rank
    FROM 
        SalesByDemographics
)
SELECT 
    s.cd_gender,
    s.cd_marital_status,
    s.avg_sales,
    s.avg_orders,
    CASE 
        WHEN s.sales_rank <= 3 THEN 'Top Performer'
        WHEN s.sales_rank > 3 AND s.sales_rank <= 10 THEN 'Above Average'
        ELSE 'Average or Below'
    END AS performance_category
FROM 
    SalesRanks s
WHERE 
    s.avg_sales > 1000
ORDER BY 
    s.avg_sales DESC;
