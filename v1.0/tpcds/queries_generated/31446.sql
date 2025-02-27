
WITH RECURSIVE MonthlySales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price)
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year < (SELECT MAX(d2.d_year) FROM date_dim d2)
    GROUP BY 
        d.d_year
),
SalesComparisons AS (
    SELECT 
        m.d_year,
        m.total_sales AS current_year_sales,
        LAG(m.total_sales) OVER (ORDER BY m.d_year) AS previous_year_sales,
        (m.total_sales - LAG(m.total_sales) OVER (ORDER BY m.d_year)) / NULLIF(LAG(m.total_sales) OVER (ORDER BY m.d_year), 0) * 100 AS sales_growth_percentage
    FROM 
        MonthlySales m
)
SELECT 
    s.d_year,
    COALESCE(s.current_year_sales, 0) AS current_year_sales,
    COALESCE(s.previous_year_sales, 0) AS previous_year_sales,
    COALESCE(s.sales_growth_percentage, 0) AS sales_growth_percentage
FROM 
    SalesComparisons s
FULL OUTER JOIN 
    date_dim d ON s.d_year = d.d_year
WHERE 
    d.d_year IS NOT NULL 
ORDER BY 
    s.d_year DESC;

-- Additional complex query exhibiting various SQL features
SELECT 
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    CASE 
        WHEN COUNT(DISTINCT c.c_customer_id) > 0 THEN SUM(ws.ws_net_profit) / COUNT(DISTINCT c.c_customer_id)
        ELSE 0
    END AS avg_profit_per_customer
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ws.ws_net_profit) > 50000
ORDER BY 
    total_profit DESC
LIMIT 10;
