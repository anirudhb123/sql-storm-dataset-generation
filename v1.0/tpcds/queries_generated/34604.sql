
WITH RECURSIVE CustomerSalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_sales_price) > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) + cs.total_sales
    FROM 
        customer c
    INNER JOIN 
        CustomerSalesCTE cs ON c.c_customer_sk = cs.c_customer_sk 
    JOIN 
        catalog_sales csell ON c.c_customer_sk = csell.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(csell.cs_sales_price) > 500
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSalesCTE cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
FilteredSales AS (
    SELECT 
        rs.c_customer_sk,
        rs.c_first_name,
        rs.c_last_name,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    COALESCE(f.total_sales, 0) AS total_sales,
    COALESCE(f.total_sales, 0) * 0.1 AS sales_bonus,
    NOW() AS report_generated_at
FROM 
    customer c
LEFT JOIN 
    FilteredSales f ON c.c_customer_sk = f.c_customer_sk
ORDER BY 
    full_name;
