
WITH RECURSIVE SalesTrend AS (
    SELECT 
        d_year AS year,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year >= 2020
    GROUP BY 
        d_year
    UNION ALL
    SELECT 
        s.year - 1 AS year,
        SUM(cs_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM
        catalog_sales cs
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN
        SalesTrend s ON s.year = d.d_year + 1
    GROUP BY 
        s.year - 1
)
SELECT 
    ca_city, 
    SUM(ss_net_profit) AS city_total_profit,
    AVG(ss_quantity) AS avg_quantity_sold,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    MAX(ss_sales_price) AS max_sales_price,
    string_agg(DISTINCT c_email_address, ', ') AS emails
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesTrend st ON st.year = 2022
WHERE 
    ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim 
        WHERE d_year = 2022
    )
    AND (ca_city IS NOT NULL AND ca_country = 'USA')
GROUP BY 
    ca_city
HAVING 
    SUM(ss_net_profit) > 10000
ORDER BY 
    city_total_profit DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
