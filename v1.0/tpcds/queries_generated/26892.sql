
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        wd.web_name AS website_name,
        wd.web_url AS website_url,
        COUNT(wa.web_page_sk) AS page_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_site wd ON c.c_customer_sk = wd.web_site_sk
    LEFT JOIN 
        web_page wa ON wd.web_site_sk = wa.wp_web_page_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country, wd.web_name, wd.web_url
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    website_name,
    website_url,
    page_count
FROM 
    customer_info
WHERE 
    LENGTH(full_name) > 20 
    AND (cd_gender = 'F' OR cd_marital_status = 'M')
ORDER BY 
    page_count DESC
LIMIT 100;
