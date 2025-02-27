
WITH RECURSIVE sales_growth AS (
    SELECT 
        d.d_year AS year, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year AS year, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year < (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        d.d_year
),
yearly_stats AS (
    SELECT 
        year,
        total_net_profit,
        total_quantity,
        LAG(total_net_profit) OVER (ORDER BY year) AS previous_year_net_profit,
        CASE 
            WHEN LAG(total_net_profit) OVER (ORDER BY year) IS NULL THEN NULL
            ELSE (total_net_profit - LAG(total_net_profit) OVER (ORDER BY year)) / NULLIF(LAG(total_net_profit) OVER (ORDER BY year), 0) * 100
        END AS growth_percentage
    FROM 
        sales_growth
)
SELECT 
    y.year,
    y.total_net_profit,
    y.total_quantity,
    COALESCE(y.growth_percentage, 0) AS growth_percentage,
    (SELECT COUNT(DISTINCT c.c_customer_id) 
     FROM customer c 
     WHERE c.c_first_shipto_date_sk IN (SELECT MAX(cd_bw) FROM customer c1 JOIN store_sales ss1 ON c1.c_customer_sk = ss1.ss_customer_sk)
    ) AS unique_customers
FROM 
    yearly_stats y
ORDER BY 
    y.year;
