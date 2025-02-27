
WITH Address_City AS (
    SELECT
        ca_city,
        COUNT(*) AS city_count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS street_info
    FROM
        customer_address
    GROUP BY
        ca_city
),
Top_Cities AS (
    SELECT
        ca_city,
        city_count,
        street_info,
        ROW_NUMBER() OVER (ORDER BY city_count DESC) AS city_rank
    FROM
        Address_City
),
Customer_Gender AS (
    SELECT
        cd_gender,
        COUNT(*) AS gender_count
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
Promotions_Stats AS (
    SELECT
        p_channel_dmail,
        p_channel_email,
        COUNT(*) AS promo_count
    FROM
        promotion
    WHERE
        p_discount_active = 'Y'
    GROUP BY
        p_channel_dmail, p_channel_email
)
SELECT
    t.ca_city,
    t.city_count,
    t.street_info,
    g.cd_gender,
    g.gender_count,
    p.promo_count
FROM
    Top_Cities t
JOIN
    Customer_Gender g ON g.gender_count = (SELECT MAX(g2.gender_count) FROM Customer_Gender g2)
LEFT JOIN
    Promotions_Stats p ON p.p_channel_dmail = 'Y' OR p.p_channel_email = 'Y'
WHERE
    t.city_rank <= 10
ORDER BY
    t.city_count DESC;
