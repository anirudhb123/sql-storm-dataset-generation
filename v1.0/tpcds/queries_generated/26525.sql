
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        da.ca_city, 
        da.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
date_range AS (
    SELECT 
        d.d_date_id,
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
web_sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        w.wp_url
    FROM 
        web_sales ws
    JOIN 
        web_page w ON ws.ws_web_page_sk = w.wp_web_page_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(wsi.ws_sales_price * wsi.ws_quantity) AS total_sales,
    COUNT(DISTINCT wsi.ws_order_number) AS order_count
FROM 
    customer_info ci
LEFT JOIN 
    web_sales_info wsi ON ci.c_customer_id = wsi.ws_order_number
LEFT JOIN 
    date_range dr ON wsi.d_date_id = dr.d_date_id
GROUP BY 
    ci.c_customer_id, ci.c_first_name, ci.c_last_name, ci.ca_city, ci.ca_state, ci.cd_gender, ci.cd_marital_status
HAVING 
    SUM(wsi.ws_sales_price * wsi.ws_quantity) > 1000
ORDER BY 
    total_sales DESC;
