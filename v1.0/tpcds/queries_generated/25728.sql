
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(UPPER(ca_street_name), ' ', ca_suite_number) AS formatted_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM customer_address
    WHERE ca_country = 'USA'
),
PromoDetails AS (
    SELECT 
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        SUBSTRING(p.p_channel_details, 1, 30) AS short_channel_details
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
CustomerWithPromo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ad.formatted_address,
        p.p_promo_name,
        p.short_channel_details,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY p.p_start_date_sk DESC) AS promo_rank
    FROM customer c
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN PromoDetails p ON p.p_promo_id = (SELECT TOP 1 p.p_promo_id 
                                                  FROM promotion p 
                                                  WHERE p.p_start_date_sk <= c.c_first_sales_date_sk 
                                                  ORDER BY p.p_start_date_sk DESC)
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ad.formatted_address,
    p.p_promo_name,
    p.short_channel_details
FROM CustomerWithPromo p
JOIN customer_demographics cd ON p.c_customer_id = cd.cd_demo_sk
WHERE p.promo_rank = 1 AND cd.cd_gender = 'F'
ORDER BY ad.formatted_address, c.c_last_name;
