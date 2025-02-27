
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
PromoDetails AS (
    SELECT 
        p_promo_sk,
        p_promo_name,
        CASE 
            WHEN p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS promo_status
    FROM 
        promotion
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    pd.promo_name,
    pd.promo_status,
    ss.total_sales,
    ss.total_sales_price,
    ss.avg_net_profit
FROM 
    AddressDetails ad
JOIN 
    SalesSummary ss ON ss.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_desc LIKE '%special%')
JOIN 
    PromoDetails pd ON pd.p_promo_sk IN (SELECT p_promo_sk FROM promotion WHERE p_channel_email = 'Y')
WHERE 
    ad.ca_state = 'NY'
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
