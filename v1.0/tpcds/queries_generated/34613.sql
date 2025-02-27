
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
customer_return_data AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
ranked_customers AS (
    SELECT 
        crd.c_customer_id,
        crd.total_returns,
        RANK() OVER (ORDER BY crd.total_returns DESC) AS return_rank
    FROM 
        customer_return_data crd
),
website_promo_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws.web_site_id
)
SELECT 
    s.web_site_id,
    ss.total_quantity,
    ss.total_sales,
    wpd.total_discount,
    wpd.order_count,
    MAX(rc.return_rank) AS max_return_rank
FROM 
    sales_summary ss
JOIN 
    website_promo_data wpd ON ss.web_site_sk = wpd.ws_web_site_sk
LEFT JOIN 
    ranked_customers rc ON rc.return_rank = 1
GROUP BY 
    s.web_site_id, ss.total_quantity, ss.total_sales, wpd.total_discount, wpd.order_count
HAVING 
    ss.total_sales > 10000 AND wpd.order_count > 5
ORDER BY 
    ss.total_sales DESC;
