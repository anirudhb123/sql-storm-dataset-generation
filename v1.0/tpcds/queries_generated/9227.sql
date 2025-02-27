
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
        AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                   AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
MostActiveCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.order_count,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    mac.c_customer_id,
    mac.total_sales,
    mac.order_count,
    mac.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    MostActiveCustomers mac
JOIN 
    customer_demographics cd ON mac.c_customer_id = cd.cd_demo_sk
WHERE 
    mac.sales_rank <= 10
ORDER BY 
    mac.total_sales DESC;
