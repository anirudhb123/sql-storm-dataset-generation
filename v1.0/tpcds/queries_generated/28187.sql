
WITH AddressDetails AS (
    SELECT 
        ca_state, 
        ca_city, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date_id,
        d_date,
        d_month_seq,
        d_quarter_seq,
        d_year,
        d_day_name
    FROM 
        date_dim
    WHERE 
        d_year IN (2022, 2023) 
),
WebDetails AS (
    SELECT 
        wp.web_name,
        wp.wp_url,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
        SUM(wp.wp_char_count) AS total_char_count
    FROM 
        web_page wp
    GROUP BY 
        wp.web_name, wp.wp_url
)
SELECT 
    ad.ca_state, 
    ad.ca_city,
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    dd.d_date_id, 
    dd.d_date, 
    wd.web_name, 
    wd.wp_url,
    wd.page_count,
    wd.total_char_count
FROM 
    AddressDetails ad 
JOIN 
    CustomerInfo ci ON ad.ca_city LIKE '%' || ci.c_city || '%'
JOIN 
    DateDetails dd ON dd.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)
JOIN 
    WebDetails wd ON wd.wp_url LIKE '%' || ci.c_email_address || '%'
ORDER BY 
    ad.ca_state, ad.ca_city, ci.c_last_name;
