
WITH AddressData AS (
    SELECT 
        ca_address_id,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        SUBSTRING(ca_city, 1, 10) AS short_city,
        UPPER(ca_country) AS upper_country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
CustomerData AS (
    SELECT 
        c_customer_id,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WebPages AS (
    SELECT 
        wp.web_page_id,
        wp.wp_url,
        LEN(wp.wp_url) AS url_length
    FROM 
        web_page wp
    WHERE 
        wp_autogen_flag = 'Y'
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.ca_address_id,
    ca.full_address,
    cu.full_name,
    cu.cd_gender,
    cu.cd_marital_status,
    ws.total_sales,
    ws.order_count,
    wp.url_length,
    wp.wp_url
FROM 
    AddressData ca
JOIN 
    CustomerData cu ON cu.c_customer_id = (
        SELECT c_customer_id 
        FROM customer 
        WHERE c_current_addr_sk = ca.ca_address_id 
        LIMIT 1
    )
LEFT JOIN 
    SalesSummary ws ON ws.ws_bill_customer_sk = cu.c_customer_sk
LEFT JOIN 
    WebPages wp ON wp.web_page_id = (
        SELECT wp.web_page_id 
        FROM web_page wp 
        WHERE wp.wp_web_page_sk < 1000 
        ORDER BY LEN(wp.wp_url) DESC 
        LIMIT 1
    )
WHERE 
    ca.short_city LIKE 'New%' 
ORDER BY 
    ca.full_address, cu.full_name;
