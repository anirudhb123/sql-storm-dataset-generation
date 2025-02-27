
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS birth_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND ca.ca_state IN ('CA', 'NY')
),
SalesInfo AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
),
Benchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        si.total_sales,
        si.total_orders,
        STRING_AGG(ci.c_email_address, ', ') AS emails
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.birth_rank = 1
    GROUP BY 
        ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.ca_city, si.total_sales, si.total_orders
)
SELECT 
    *
FROM 
    Benchmark
WHERE 
    total_sales > 1000
ORDER BY 
    total_orders DESC, total_sales DESC;
