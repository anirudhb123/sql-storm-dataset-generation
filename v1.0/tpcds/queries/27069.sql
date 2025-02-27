WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_address
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(CASE WHEN ws_ship_date_sk IS NOT NULL THEN ws_quantity ELSE 0 END) AS total_sales_quantity,
        SUM(ws_net_paid) AS total_sales_amount
    FROM 
        web_sales 
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.address_count, 
    ad.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.customer_count,
    ci.customer_names,
    ss.d_year,
    ss.total_sales_quantity,
    ss.total_sales_amount
FROM 
    AddressDetails ad
JOIN 
    CustomerInfo ci ON ad.ca_city = ci.cd_gender 
JOIN 
    SalesSummary ss ON ss.total_sales_quantity > 0
WHERE 
    ad.address_count > 10 
ORDER BY 
    ad.ca_city, ci.cd_marital_status, ss.d_year DESC;