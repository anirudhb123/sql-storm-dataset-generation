
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_state ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_state
),
high_rollers AS (
    SELECT 
        customer_id,
        total_sales,
        total_revenue
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
),
address_details AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN ca.ca_country IS NULL THEN 'Unknown'
            ELSE ca.ca_country 
        END AS display_country
    FROM 
        customer_address ca 
        LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    h.customer_id,
    h.total_sales,
    h.total_revenue,
    ad.ca_city,
    ad.ca_state,
    ad.display_country
FROM 
    high_rollers h
LEFT JOIN 
    address_details ad ON h.customer_id = ad.ca_address_id
WHERE 
    h.total_revenue > (SELECT AVG(total_revenue) FROM high_rollers)
ORDER BY 
    h.total_revenue DESC
LIMIT 50;
