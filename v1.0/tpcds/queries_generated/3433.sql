
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546  -- Filtering dates (e.g., over a specific period)
    GROUP BY 
        ws.web_site_sk
),
top_sales AS (
    SELECT 
        web_site_sk,
        total_sales,
        total_orders,
        avg_net_profit
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 5  -- Top 5 websites by sales
),
address_details AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    ts.web_site_sk,
    ts.total_sales,
    ts.total_orders,
    ts.avg_net_profit,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    ad.customer_count
FROM 
    top_sales ts
JOIN 
    address_details ad ON ts.web_site_sk = (
        SELECT 
            wa.w_warehouse_sk 
        FROM 
            warehouse wa 
        WHERE 
            wa.w_country = ad.ca_country
        LIMIT 1
    )
ORDER BY 
    ts.total_sales DESC;
