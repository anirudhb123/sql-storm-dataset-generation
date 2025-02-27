
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS avg_profit,
        d.year AS sales_year,
        c.c_birth_year AS customer_birth_year,
        cd.marital_status AS customer_marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE 
        d.year BETWEEN 2018 AND 2022
    GROUP BY 
        ws.bill_customer_sk, d.year, c.c_birth_year, cd.marital_status
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sales_year, customer_marital_status ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    sales_year,
    customer_birth_year,
    customer_marital_status,
    total_sales,
    total_orders,
    avg_profit
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_year, customer_marital_status, total_sales DESC;
