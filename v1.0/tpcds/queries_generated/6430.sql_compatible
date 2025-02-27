
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
), 
TopWebSites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        order_count 
    FROM 
        RankedSales 
    WHERE 
        rank_sales <= 5
)
SELECT 
    t.web_site_id,
    t.total_sales,
    t.order_count,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopWebSites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
JOIN 
    customer c ON w.web_site_sk = c.c_current_addr_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    t.total_sales > (SELECT AVG(total_sales) FROM TopWebSites)
ORDER BY 
    t.total_sales DESC;
