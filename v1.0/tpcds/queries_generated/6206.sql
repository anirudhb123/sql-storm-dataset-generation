
WITH ranked_sales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_id
),
top_websites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        rank <= 5
)
SELECT
    t.web_site_id,
    t.total_sales,
    t.order_count,
    w.w_warehouse_name,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city,
    ca.ca_state
FROM 
    top_websites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
JOIN 
    web_sales ws ON ws.ws_web_site_sk = w.web_site_sk
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    t.total_sales DESC;
