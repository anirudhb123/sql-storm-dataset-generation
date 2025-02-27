
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        ranked_customers rc
    WHERE 
        rc.purchase_rank <= 5
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    COUNT(DISTINCT web.web_site_id) AS total_websites_visited,
    COUNT(DISTINCT wu.wp_url) AS unique_web_page_views,
    SUM(CASE WHEN w.wp_char_count > 500 THEN 1 ELSE 0 END) AS long_content_views
FROM 
    top_customers tc
LEFT JOIN 
    web_page wu ON wu.wp_customer_sk = tc.c_customer_sk
LEFT JOIN 
    web_site w ON w.web_site_sk = wu.wp_web_page_sk
GROUP BY 
    tc.full_name, tc.cd_gender, tc.cd_marital_status, tc.cd_education_status
ORDER BY 
    total_websites_visited DESC;
