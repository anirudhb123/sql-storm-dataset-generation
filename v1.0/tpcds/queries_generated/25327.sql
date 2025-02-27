
WITH AddressInfo AS (
    SELECT 
        ca_street_name,
        ca_city,
        ca_state,
        ca_country,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address
    FROM 
        customer_address
),
WebPageInfo AS (
    SELECT 
        wp_url,
        wp_type,
        wp_char_count,
        wp_link_count,
        wp_image_count,
        wp_max_ad_count
    FROM 
        web_page
),
SalesData AS (
    SELECT 
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ws_ext_sales_price,
        ws_ext_tax
    FROM 
        web_sales
)
SELECT 
    ai.full_address,
    wp.wp_url,
    wp.wp_type,
    SUM(sd.ws_quantity) AS total_quantity,
    AVG(sd.ws_sales_price) AS avg_sales_price,
    AVG(sd.ws_net_paid) AS avg_net_paid,
    SUM(sd.ws_ext_sales_price) AS total_ext_sales_price,
    SUM(sd.ws_ext_tax) AS total_ext_tax,
    COUNT(DISTINCT wp.wp_web_page_id) AS unique_web_pages,
    SUM(wp.wp_char_count) AS total_char_count,
    SUM(wp.wp_image_count) AS total_image_count
FROM 
    AddressInfo ai
JOIN 
    SalesData sd ON 1=1
JOIN 
    WebPageInfo wp ON 1=1
GROUP BY 
    ai.full_address, wp.wp_url, wp.wp_type
HAVING 
    total_quantity > 100
ORDER BY 
    total_ext_sales_price DESC;
