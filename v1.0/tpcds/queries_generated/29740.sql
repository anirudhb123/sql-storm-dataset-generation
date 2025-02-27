
WITH processed_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city || ', ' || ca.ca_state AS full_address,
        CONCAT(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category,
        string_agg(DISTINCT DISTINCT wp.wp_url, ', ') AS web_page_urls,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_purchase_estimate
)
SELECT 
    full_name,
    full_address,
    gender_marital,
    purchase_estimate_category,
    web_page_urls,
    order_count
FROM 
    processed_data
WHERE 
    order_count > 5
ORDER BY 
    purchase_estimate_category DESC, order_count DESC;
