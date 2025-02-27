
WITH RECURSIVE sales_growth AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
    HAVING 
        d_year >= (SELECT MAX(d_year) FROM date_dim) - 5
),
yearly_growth AS (
    SELECT 
        d_year,
        total_profit,
        LEAD(total_profit) OVER (ORDER BY d_year) AS next_year_profit
    FROM 
        sales_growth
),
growth_rate AS (
    SELECT 
        d_year,
        (CASE 
            WHEN next_year_profit IS NOT NULL THEN 
                (total_profit - next_year_profit) / NULLIF(next_year_profit, 0)
            ELSE 
                NULL 
        END) AS growth_percentage
    FROM 
        yearly_growth
),
customer_info AS (
    SELECT 
        ca.city, 
        cd.cd_gender, 
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.city, cd.cd_gender
),
overall_summary AS (
    SELECT 
        ci.city,
        ci.cd_gender,
        ci.customer_count,
        COALESCE(g.growth_percentage, 0) AS growth_percentage
    FROM 
        customer_info ci
    LEFT JOIN 
        growth_rate g ON g.d_year = (SELECT MAX(d_year) FROM sales_growth)
)
SELECT 
    os.city,
    os.cd_gender,
    os.customer_count,
    os.growth_percentage,
    CASE 
        WHEN os.customer_count > 100 THEN 'High'
        WHEN os.customer_count BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS category
FROM 
    overall_summary os
WHERE 
    os.growth_percentage IS NOT NULL
ORDER BY 
    os.customer_count DESC, os.growth_percentage DESC;
