
WITH SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        cs.cs_sales_price AS catalog_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    s.d_year,
    s.total_sales,
    s.order_count,
    s.avg_sales_price,
    c.cd_gender,
    c.unique_customers,
    c.total_quantity,
    (s.total_sales / NULLIF(c.total_quantity, 0)) AS sales_per_quantity
FROM 
    SalesData s
JOIN 
    CustomerData c ON s.d_year = (SELECT DISTINCT d_year FROM SalesData WHERE d_year <= s.d_year)
ORDER BY 
    s.d_year, c.cd_gender;
