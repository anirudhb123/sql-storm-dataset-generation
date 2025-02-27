
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND ws.ws_ship_mode_sk IN (
            SELECT sm_ship_mode_sk 
            FROM ship_mode 
            WHERE sm_carrier = 'FedEx'
        )
    GROUP BY 
        ws.web_site_id
), SiteRank AS (
    SELECT 
        web_site_id, 
        total_sales,
        order_count,
        rank
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    s.web_site_id,
    s.total_sales,
    s.order_count,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    SiteRank s
JOIN 
    web_site ws ON s.web_site_id = ws.web_site_id
JOIN 
    warehouse w ON ws.web_site_id = w.w_warehouse_id
JOIN 
    customer c ON c.c_current_addr_sk = w.w_warehouse_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    s.web_site_id, s.total_sales, s.order_count, ca.ca_city, ca.ca_state
ORDER BY 
    s.total_sales DESC;
