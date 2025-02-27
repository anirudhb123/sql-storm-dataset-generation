
WITH RankedSales AS (
    SELECT 
        ws.sold_date_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers,
        RANK() OVER (PARTITION BY ws.sold_date_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_gender = 'F'
        AND dd.d_year = 2023
        AND dd.d_moy IN (6, 7)
    GROUP BY 
        ws.sold_date_sk
), TopSales AS (
    SELECT 
        sold_date_sk,
        total_sales,
        unique_customers
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    dd.d_date,
    ts.total_sales,
    ts.unique_customers,
    CONCAT(COALESCE(ca.ca_city, 'N/A'), ', ', COALESCE(ca.ca_state, 'N/A')) AS location
FROM 
    TopSales ts
JOIN 
    date_dim dd ON ts.sold_date_sk = dd.d_date_sk
LEFT JOIN 
    customer c ON c.c_first_shipto_date_sk = dd.d_date_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    dd.d_date ASC, 
    ts.total_sales DESC;
