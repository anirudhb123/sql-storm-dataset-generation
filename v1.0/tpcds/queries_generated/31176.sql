
WITH RecursiveDateCTE AS (
    SELECT 
        d_date_sk,
        d_date,
        d_year,
        d_month_seq,
        d_week_seq,
        1 AS level
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2022-01-01' AND '2023-12-31'
    
    UNION ALL
    
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        r.level + 1
    FROM 
        date_dim d
    JOIN 
        RecursiveDateCTE r ON d.d_date_sk = r.d_date_sk + 1
)

SELECT 
    ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_net_profit,
    STRING_AGG(DISTINCT CAST(d.d_date AS VARCHAR), ', ') AS sales_dates
FROM 
    customer c 
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    RecursiveDateCTE rd ON rd.d_date_sk = ws.ws_sold_date_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND (ws.ws_ext_sales_price > 50 OR ws.ws_net_profit < 0)
    AND rd.level <= 12
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_sales DESC
LIMIT 10;
