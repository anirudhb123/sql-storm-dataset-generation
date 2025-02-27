
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id, ws.web_name
),
TopSales AS (
    SELECT 
        rs.web_site_id,
        rs.web_name,
        rs.total_sales,
        rs.order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ts.total_sales) AS total_sales_contributed
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    TopSales ts ON ts.web_site_id IN (
        SELECT 
            ws.web_site_id 
        FROM 
            web_sales ws
        JOIN 
            web_site w ON ws.ws_web_site_sk = w.web_site_sk
        WHERE 
            ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        GROUP BY 
            ws.web_site_id
        HAVING 
            SUM(ws.ws_sales_price) = (
                SELECT 
                    MAX(total_sales) 
                FROM 
                    TopSales
            )
    )
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales_contributed DESC;
