
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_type || ' ' || ca_street_number, ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicAddress AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        ad.ca_city,
        ad.ca_state,
        ad.address_count,
        ad.full_address_list
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
),
PromotionsCount AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS web_sales_count,
        COUNT(cs.cs_order_number) AS catalog_sales_count,
        COUNT(ss.ss_ticket_number) AS store_sales_count
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    LEFT JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN 
        store_sales ss ON p.p_promo_sk = ss.ss_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.ca_city,
    da.ca_state,
    da.address_count,
    da.full_address_list,
    pc.p_promo_name,
    pc.web_sales_count,
    pc.catalog_sales_count,
    pc.store_sales_count
FROM 
    DemographicAddress da
JOIN 
    PromotionsCount pc ON da.ca_city = pc.ca_city AND da.ca_state = pc.ca_state
WHERE 
    da.address_count > 5
ORDER BY 
    da.ca_state, da.ca_city, pc.web_sales_count DESC;
