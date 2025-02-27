
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    SUM(CASE 
        WHEN cd_gender = 'F' THEN 1 
        ELSE 0 
        END) AS female_count,
    SUM(CASE 
        WHEN cd_gender = 'M' THEN 1 
        ELSE 0 
        END) AS male_count,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    COUNT(DISTINCT wd.web_site_id) AS web_visits,
    STRING_AGG(DISTINCT CONCAT(wp_url, ' (', wp_type, ')'), '; ') AS visited_pages
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_page wp ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN 
    web_site wd ON wd.web_site_sk = wp.wp_customer_sk
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    customer_count DESC;
