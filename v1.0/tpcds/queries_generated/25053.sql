
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        RTRIM(ca_street_number) || ' ' || 
        RTRIM(ca_street_name) || ' ' || 
        RTRIM(ca_street_type) AS full_address
    FROM 
        customer_address
),
Demographics_Full AS (
    SELECT 
        cd_demo_sk,
        CONCAT_WS(' ', cd_gender, cd_marital_status, cd_education_status) AS demographic_info
    FROM 
        customer_demographics
),
Sales_Info AS (
    SELECT 
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_item_sk) AS items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
),
Promotion_Details AS (
    SELECT 
        p_promo_sk,
        TRIM(p_promo_name) AS promo_name,
        TRIM(p_channel_details) AS channel_details
    FROM 
        promotion
)
SELECT 
    a.full_address,
    d.demographic_info,
    s.total_sales,
    p.promo_name,
    p.channel_details
FROM 
    Address_Concat a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    Demographics_Full d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    Sales_Info s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    Promotion_Details p ON s.ws_order_number = p.p_promo_sk
WHERE 
    a.full_address LIKE '%Street%'
ORDER BY 
    s.total_sales DESC
LIMIT 100;
