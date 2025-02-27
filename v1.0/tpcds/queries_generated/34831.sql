
WITH RECURSIVE SalesTrend AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS rnk
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date >= '2023-01-01' AND d.d_date <= '2023-12-31'
    GROUP BY 
        d.d_date
    UNION ALL
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) + st.total_net_profit AS total_net_profit,
        rnk + 1
    FROM 
        date_dim d
    JOIN 
        SalesTrend st ON d.d_date_sk = st.rnk
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        rnk < 30 AND d.d_date > (SELECT MAX(d_date) FROM date_dim WHERE d_date_sk <= st.rnk)
)
SELECT 
    ca.ca_city,
    avg(hd.hd_vehicle_count) AS avg_vehicle_count,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    MAX(ws.ws_net_profit) AS max_web_net_profit,
    COALESCE(STRING_AGG(DISTINCT CONCAT(cp.cp_description, ' (', cp.cp_catalog_page_id, ')'), ', '), 'No catalog pages') AS associated_catalogs
FROM 
    customer c
INNER JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_page cp ON ws.ws_bill_addr_sk = cp.cp_catalog_page_sk
WHERE 
    hd.hd_vehicle_count IS NOT NULL
    AND (ca.ca_city LIKE 'San%' OR ca.ca_city IS NULL)
GROUP BY 
    ca.ca_city
ORDER BY 
    avg_vehicle_count DESC
LIMIT 10;
