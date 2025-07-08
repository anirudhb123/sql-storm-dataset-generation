
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn,
        c.c_birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
AddressDistributions AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
PromotionsStats AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ad.ca_state,
    ad.address_count,
    ad.cities,
    ps.p_promo_name,
    ps.total_orders,
    ps.total_sales
FROM 
    RankedCustomers rc
JOIN 
    AddressDistributions ad ON TRUE 
JOIN 
    PromotionsStats ps ON TRUE 
WHERE 
    rc.rn <= 10 
ORDER BY 
    rc.cd_gender, rc.c_birth_year DESC, ps.total_sales DESC;
