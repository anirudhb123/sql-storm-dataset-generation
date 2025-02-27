
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_ship_mode_sk
    HAVING 
        SUM(ws_sales_price) > (SELECT AVG(ws_sales_price) FROM web_sales) * 0.5
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_address_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales(ws) ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_address_sk, cd.cd_gender
),
daily_sales_analysis AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_sales_price) AS daily_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_single_sale,
        MIN(ws.ws_sales_price) AS min_single_sale
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    SUM(s.total_sales) AS total_sales,
    d.sale_date,
    d.daily_sales,
    d.total_orders,
    COALESCE(r.r_reason_desc, 'No Reason') AS return_reason
FROM 
    customer c
JOIN 
    customer_details cd ON c.c_customer_sk = cd.c_customer_sk
JOIN 
    sales_cte s ON s.ws_ship_mode_sk = (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_sm_code = 'GROUND' LIMIT 1)
JOIN 
    daily_sales_analysis d ON d.sale_date = CURRENT_DATE
LEFT JOIN 
    reason r ON r.r_reason_sk = (SELECT sr_reason_sk FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk ORDER BY sr.sr_return_quantity DESC LIMIT 1)
WHERE 
    cd.order_count > 5 
    AND COALESCE(c.c_birth_country, 'UNKNOWN') != 'UNKNOWN'
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, d.sale_date, d.daily_sales, d.total_orders, r.r_reason_desc
ORDER BY 
    total_sales DESC, d.sale_date DESC;
