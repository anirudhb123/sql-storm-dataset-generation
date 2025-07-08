
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name ASC, c.c_first_name ASC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressWithCount AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_last_name, c.c_first_name) AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
),
DateRange AS (
    SELECT 
        MIN(d.d_date) AS start_date,
        MAX(d.d_date) AS end_date
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2001
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    ac.customer_count,
    ac.customer_names,
    dr.start_date,
    dr.end_date
FROM 
    RankedCustomers rc
JOIN 
    AddressWithCount ac ON rc.c_customer_id = ac.customer_names 
CROSS JOIN 
    DateRange dr
WHERE 
    rc.rn <= 5 
ORDER BY 
    rc.cd_gender, rc.c_last_name, rc.c_first_name;
