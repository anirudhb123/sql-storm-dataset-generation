
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store s ON s.s_store_sk IN (SELECT DISTINCT sr.sr_store_sk FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk)
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        promotion p ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type
),
DateRange AS (
    SELECT 
        MIN(d.d_date) AS start_date,
        MAX(d.d_date) AS end_date
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.promotions,
    dr.start_date,
    dr.end_date
FROM 
    CustomerDetails cd
CROSS JOIN 
    DateRange dr
WHERE 
    cd.ca_state = 'CA' AND 
    cd.cd_marital_status IN ('M', 'S')
ORDER BY 
    cd.full_name;
