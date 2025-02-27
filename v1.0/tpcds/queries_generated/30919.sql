
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_order_number,
        1 AS depth
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_order_number,
        sd.depth + 1
    FROM 
        web_sales ws
    JOIN 
        sales_data sd ON ws.web_site_id = sd.web_site_id
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) - sd.depth FROM date_dim)
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        COALESCE(CD.cd_gender, 'U') AS gender,
        COALESCE(HD.hd_buy_potential, 'Unknown') AS buy_potential,
        SUM(ws.ws_quantity) AS total_sales_quantity
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    LEFT JOIN 
        household_demographics HD ON CD.cd_demo_sk = HD.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id, CD.cd_gender, HD.hd_buy_potential
),
total_sales AS (
    SELECT 
        site.web_site_id,
        SUM(sd.ws_sales_price) AS total_site_sales,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders
    FROM 
        sales_data sd
    JOIN 
        web_site site ON sd.web_site_id = site.web_site_id
    GROUP BY 
        site.web_site_id
)
SELECT 
    ci.c_customer_id,
    ci.gender,
    ci.buy_potential,
    ts.total_site_sales,
    ts.total_orders,
    CASE 
        WHEN ci.total_sales_quantity IS NULL THEN 'No Sales'
        WHEN ci.total_sales_quantity > 10 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    customer_info ci
FULL OUTER JOIN 
    total_sales ts ON ci.total_sales_quantity > 0
ORDER BY 
    ts.total_site_sales DESC, ci.c_customer_id
LIMIT 100;
