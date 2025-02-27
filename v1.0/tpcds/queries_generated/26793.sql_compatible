
WITH CustomerAddressDetails AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        COUNT(c.c_customer_sk) AS customers_count,
        STRING_AGG(DISTINCT cd.education_status) AS unique_education_statuses,
        STRING_AGG(DISTINCT CASE WHEN cd.gender = 'M' THEN c.first_name END) AS male_first_names,
        STRING_AGG(DISTINCT CASE WHEN cd.gender = 'F' THEN c.first_name END) AS female_first_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
),
DateDetails AS (
    SELECT 
        d.d_year,
        COUNT(ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    d.d_year,
    ad.address_city,
    ad.address_state,
    ad.customers_count,
    ad.unique_education_statuses,
    ad.male_first_names,
    ad.female_first_names,
    d.total_web_sales,
    d.total_net_profit
FROM 
    CustomerAddressDetails ad
JOIN 
    DateDetails d ON ad.address_city = 'Los Angeles' AND ad.address_state = 'CA'
ORDER BY 
    d.d_year DESC, ad.customers_count DESC;
