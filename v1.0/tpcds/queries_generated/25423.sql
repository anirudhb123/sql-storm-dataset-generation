
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
PromoCounts AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT cs_order_number) AS total_sales
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_name
),
WebPageStats AS (
    SELECT 
        wp_type,
        COUNT(*) AS total_pages,
        SUM(wp_char_count) AS total_chars,
        AVG(wp_char_count) AS avg_chars_per_page
    FROM 
        web_page
    GROUP BY 
        wp_type
)
SELECT 
    as.ca_state,
    as.unique_addresses,
    as.max_street_name_length,
    as.min_street_name_length,
    as.avg_street_name_length,
    pc.p_promo_name,
    pc.total_sales,
    wps.wp_type,
    wps.total_pages,
    wps.total_chars,
    wps.avg_chars_per_page
FROM 
    AddressStats as
JOIN 
    PromoCounts pc ON 1 = 1
JOIN 
    WebPageStats wps ON 1 = 1
ORDER BY 
    as.ca_state, 
    pc.total_sales DESC, 
    wps.total_chars DESC;
