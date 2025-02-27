
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS average_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promotion_usage
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ISNULL(i.total_sales, 0) AS total_item_sales,
    ISNULL(i.average_price, 0) AS average_item_price,
    ISNULL(p.promotion_usage, 0) AS promotion_usage_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    ItemSales i ON ci.c_customer_sk = i.ws_item_sk
LEFT JOIN 
    Promotions p ON p.p_promo_sk = (SELECT TOP 1 p.p_promo_sk FROM promotion p ORDER BY NEWID())
WHERE 
    ci.cd_gender = 'F' AND 
    ci.cd_marital_status = 'M'
ORDER BY 
    ci.full_name;
