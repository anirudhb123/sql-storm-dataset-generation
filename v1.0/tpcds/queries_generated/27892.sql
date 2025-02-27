
WITH AddressZipCounts AS (
    SELECT 
        ca_zip,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_zip
),
UniqueCustomers AS (
    SELECT DISTINCT 
        c_customer_id, 
        c_first_name, 
        c_last_name, 
        ca.city, 
        ca.state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PromotionDetails AS (
    SELECT 
        p.promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.promo_name
),
TopShippingModes AS (
    SELECT 
        sm.sm_type,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        ship_mode sm
    JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_type
    ORDER BY 
        order_count DESC
    LIMIT 5
)
SELECT 
    uc.c_first_name,
    uc.c_last_name,
    uc.city,
    uc.state,
    tc.address_count,
    pd.promo_name,
    pd.total_orders,
    pd.total_revenue,
    tsm.sm_type,
    tsm.order_count
FROM 
    UniqueCustomers uc
LEFT JOIN 
    AddressZipCounts tc ON uc.city = tc.ca_zip
LEFT JOIN 
    PromotionDetails pd ON pd.total_orders > 0
LEFT JOIN 
    TopShippingModes tsm ON tsm.order_count > 0
ORDER BY 
    uc.state, uc.city, uc.c_last_name, uc.c_first_name;
