
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesByGeo AS (
    SELECT 
        c.c_city,
        SUM(cs.total_sales) AS geo_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        c.c_city
),
TopRegions AS (
    SELECT 
        ca.ca_state,
        SUM(geo_sales) AS total_geo_sales
    FROM 
        SalesByGeo sg
    JOIN 
        customer c ON sg.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
    ORDER BY 
        total_geo_sales DESC
    LIMIT 5
)
SELECT 
    tr.ca_state,
    tr.total_geo_sales,
    COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
    AVG(cs.total_sales) AS avg_sales_per_customer
FROM 
    TopRegions tr
JOIN 
    CustomerSales cs ON tr.c_customer_sk = cs.c_customer_sk
GROUP BY 
    tr.ca_state, tr.total_geo_sales
ORDER BY 
    tr.total_geo_sales DESC;
