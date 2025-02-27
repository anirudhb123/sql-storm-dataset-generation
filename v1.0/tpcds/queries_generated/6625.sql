
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopSites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    ts.web_site_id,
    ts.total_quantity,
    ts.total_sales,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    TopSites ts
JOIN 
    customer_address ca ON ts.web_site_id = ca.ca_address_id
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    ts.web_site_id, ts.total_quantity, ts.total_sales, ca.ca_city, ca.ca_state
ORDER BY 
    ts.total_sales DESC;
