
WITH RECURSIVE SalesGrowth AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        LAG(SUM(ws.ws_ext_sales_price)) OVER (ORDER BY d.d_year) AS previous_year_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
GrowthRate AS (
    SELECT 
        d_year,
        total_sales,
        previous_year_sales,
        CASE 
            WHEN previous_year_sales IS NULL THEN NULL
            ELSE (total_sales - previous_year_sales) / previous_year_sales * 100 
        END AS growth_percentage
    FROM 
        SalesGrowth
),
TopGrowth AS (
    SELECT 
        d_year,
        total_sales,
        growth_percentage,
        RANK() OVER (ORDER BY growth_percentage DESC) AS growth_rank
    FROM 
        GrowthRate
)
SELECT 
    g.d_year,
    g.total_sales,
    COALESCE(g.growth_percentage, 0) AS growth_percentage,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS top_customer,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity
FROM 
    TopGrowth g
LEFT JOIN 
    web_sales ws ON ws.ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_year = g.d_year LIMIT 1)
LEFT JOIN 
    customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    g.growth_rank <= 5
GROUP BY 
    g.d_year, g.total_sales, g.growth_percentage, c.c_first_name, c.c_last_name
ORDER BY 
    g.d_year;
